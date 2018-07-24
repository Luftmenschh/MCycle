from ...bases.config cimport Config
from ...bases.flowstate cimport FlowState
from ...bases.geom cimport Geom
from ...bases.mcabstractbase cimport MCAttr
from ...bases.solidmaterial cimport SolidMaterial
from ...methods import heat_transfer as ht
from .hxunit_basicplanar cimport HxUnitBasicPlanar
from warnings import warn
from math import nan
import CoolProp as CP
import numpy as np
import scipy.optimize as opt

cdef str method

cdef class HxUnitPlate(HxUnitBasicPlanar):
    r"""Characterises a basic plate heat exchanger unit consisting of alternating working fluid and secondary fluid flows separated by a solid wall with single-phase or multi-phase working fluid but only single-phase secondary fluid.

Parameters
----------
flowSense : str, optional
    Relative direction of the working and secondary flows. May be either "counterflow" or "parallel". Defaults to "counterflow".
NPlate : int, optional
    Number of parallel plates [-]. Defaults to 3.
RfWf : float, optional
    Thermal resistance due to fouling on the working fluid side. Defaults to 0.
RfSf : float, optional
    Thermal resistance due to fouling on the secondary fluid side. Defaults to 0.
plate : SolidMaterial, optional
    Plate material. Defaults to None.
tPlate : float, optional
    Thickness of the plate [m]. Defaults to nan.
L : float, optional
    Length of the heat transfer surface area (dimension parallel to flow direction) [m]. Defaults to nan.
W : float, optional
    Width of the heat transfer surface area (dimension perpendicular to flow direction) [m]. Defaults to nan.
ARatioWf : float, optional
    Multiplier for the heat transfer surface area of the working fluid [-]. Defaults to 1.
ARatioSf : float, optional
    Multiplier for the heat transfer surface area of the secondary fluid [-]. Defaults to 1.
ARatioPlate : float, optional
    Multiplier for the heat transfer surface area of the plate [-]. Defaults to 1.
beta : float, optional
     Plate corrugation chevron angle [deg]. Defaults to nan.
phi : float, optional
     Corrugated plate surface enlargement factor; ratio of developed length to projected length. Defaults to 1.2.
pitchCor : float, optional
     Plate corrugation pitch [m] (distance between corrugation 'bumps'). Defaults to nan.
     .. note: Not to be confused with the plate pitch which is usually defined as the sum of the plate channel spacing and one plate thickness.
effThermal : float, optional
    Thermal efficiency [-]. Defaults to 1.
flowInWf : FlowState, optional
    Incoming FlowState of the working fluid. Defaults to None.
flowInSf : FlowState, optional
    Incoming FlowState of the secondary fluid. Defaults to None.
flowOutWf : FlowState, optional
    Outgoing FlowState of the working fluid. Defaults to None.
flowOutSf : FlowState, optional
    Outgoing FlowState of the secondary fluid. Defaults to None.
sizeAttr : string, optional
    Default attribute used by size(). Defaults to "L".
sizeBracket : float or list of float, optional
    Bracket containing solution of size(). Defaults to [1e-5, 10.0].

    - if sizeBracket=[a,b]: scipy.optimize.brentq is used.

    - if sizeBracket=a or [a]: scipy.optimize.newton is used.
name : string, optional
    Description of object. Defaults to "HxUnitPlateCorrugated instance".
notes : string, optional
    Additional notes on the component such as model numbers. Defaults to "No notes/model info.".
config : Config, optional
    Configuration parameters. Defaults to the default Config object.
kwargs : optional
    Arbitrary keyword arguments.
    """

    def __init__(self,
                 str flowSense="counterflow",
                 int NPlate=3,
                 double RfWf=0,
                 double RfSf=0,
                 SolidMaterial plate=None,
                 double tPlate=float("nan"),
                 Geom geomPlateWf=None,
                 Geom geomPlateSf=None,
                 double L=float("nan"),
                 double W=float("nan"),
                 double ARatioWf=1,
                 double ARatioSf=1,
                 double ARatioPlate=1,
                 double effThermal=1.0,
                 FlowState flowInWf=None,
                 FlowState flowInSf=None,
                 FlowState flowOutWf=None,
                 FlowState flowOutSf=None,
                 str sizeAttr="L",
                 list sizeBracket=[1e-5, 10.0],
                 str name="HxUnitPlateCorrugated instance",
                 str notes="No notes/model info.",
                 Config config=Config()):
        super().__init__(flowSense, -1, -1, NPlate, nan, nan, RfWf, RfSf,
                         plate, tPlate, L, W, ARatioWf, ARatioSf, ARatioPlate,
                         effThermal, flowInWf, flowInSf, flowOutWf, flowOutSf,
                         sizeAttr, sizeBracket, name, notes, config)
        self.geomPlateWf = geomPlateWf
        self.geomPlateSf = geomPlateSf
        
        self._inputs = {"flowSense": MCAttr(str, "none"), "NPlate": MCAttr(int, "none"), "RfWf": MCAttr(float, "fouling"),
                        "RfSf": MCAttr(float, "fouling"), "plate": MCAttr(SolidMaterial, "none"), "tPlate": MCAttr(float, "length"), "L": MCAttr(float, "length"), "W": MCAttr(float, "length"),
                        "ARatioWf": MCAttr(float, "none"), "ARatioSf": MCAttr(float, "none"), "ARatioPlate": MCAttr(float, "none"), "effThermal": MCAttr(float, "none"), "flowInWf": MCAttr(FlowState, "none"), "flowInSf": MCAttr(FlowState, "none"),
                        "flowOutWf": MCAttr(FlowState, "none"), "flowOutSf": MCAttr(FlowState, "none"), 
                        "sizeAttr": MCAttr(str, "none"), "sizeBracket": MCAttr(list, "none"), "name": MCAttr(str, "none"), "notes": MCAttr(str, "none"),
                        "config": MCAttr(Config, "none")}
        self._properties = {"mWf": MCAttr(float, "mass/time"), "mSf": MCAttr(float, "mass/time"), "Q()": MCAttr(float, "power"), "U()": MCAttr( "htc"), "A()": MCAttr( "area"),
                "dpWf()": MCAttr( "pressure"), "dpSf()": MCAttr( "pressure"), "isEvap()": MCAttr( "none")}

    cpdef public int _NWf(self):
        """int: Number of secondary fluid flow channels. Setter may not be used.

    - if NPlate is odd: NWf = NSf = (NPlate - 1) / 2
    - if NPlate is even: the extra flow channel is assigned according to config.evenPlatesWf.
        """
        if self.NWall & 1:  # NPlate is odd
            return int((self.NWall - 1) / 2)
        else:
            if self.config.evenPlatesWf:
                return int(self.NWall / 2)
            else:
                return int(self.NWall / 2 - 1)

    cpdef public int _NSf(self):
        """int: Number of secondary fluid flow channels. Setter may not be used.

    - if NPlate is odd: NWf = NSf = (NPlate - 1) / 2
    - if NPlate is even: the extra flow channel is assigned according to config.evenPlatesWf.
        """
        if self.NWall & 1:  # NPlate is odd
            return int((self.NWall - 1) / 2)
        else:
            if self.config.evenPlatesWf:
                return int(self.NWall / 2 - 1)
            else:
                return int(self.NWall / 2)

    cpdef public double _hWf(self):
        """float: Heat transfer coefficient of a working fluid channel [W/m^2.K]. Calculated using the relevant method of mcycle.methods.heat_transfer defined in config.methods."""
        method = self.config.lookupMethod(self.__class__.__name__,
                                            (self.geomPlateWf.__class__.__name__, "heat",
                                             self.phaseWf(), "wf"))
        return getattr(ht, method)(
            flowIn=self.flowsIn[0],
            flowOut=self.flowsOut[0],
            N=self._NWf(),
            geom=self.geomPlateWf,
            L=self.L,
            W=self.W)["h"]

    cpdef public double _hSf(self):
        """float: Heat transfer coefficient of a secondary fluid channel [W/m^2.K]. Calculated using the relevant method of mcycle.methods.heat_transfer defined in config.methods."""
        method = self.config.lookupMethod(self.__class__.__name__,
                                            (self.geomPlateSf.__class__.__name__, "heat",
                                             self.phaseSf(), "sf"))
        return getattr(ht, method)(
            flowIn=self.flowsIn[1],
            flowOut=self.flowsOut[1],
            N=self._NSf(),
            geom=self.geomPlateSf,
            L=self.L,
            W=self.W)["h"]

    cpdef public double _fWf(self):
        """float: Fanning friction factor of a working fluid channel [-]. Calculated using the relevant method of mcycle.methods.heat_transfer defined in config.methods."""
        method = self.config.lookupMethod(self.__class__.__name__,
                                            (self.geomPlateWf.__class__.__name__,
                                            "friction", self.phaseWf(), "wf"))
        return getattr(ht, method)(
            flowIn=self.flowsIn[0],
            flowOut=self.flowsOut[0],
            N=self._NWf(),
            geom=self.geomPlateWf,
            L=self.L,
            W=self.W)["f"]

    cpdef public double _fSf(self):
        """float: Fanning friction factor of a secondary fluid channel [-]. Calculated using the relevant method of mcycle.methods.heat_transfer defined in config.methods."""
        method = self.config.lookupMethod(self.__class__.__name__,
                                            (self.geomPlateSf.__class__.__name__,
                                             "friction", self.phaseSf(), "sf"))
        return getattr(ht, method)(
            flowIn=self.flowsIn[1],
            flowOut=self.flowsOut[1],
            N=self._NSf(),
            geom=self.geomPlateSf,
            L=self.L,
            W=self.W)["f"]

    cpdef public double _dpFWf(self):
        """float: Frictional pressure drop of a working fluid channel [-]. Calculated using the relevant method of mcycle.methods.heat_transfer defined in config.methods."""
        method = self.config.lookupMethod(self.__class__.__name__,
                                            (self.geomPlateWf.__class__.__name__,
                                             "friction", self.phaseWf(), "wf"))
        return getattr(ht, method)(
            flowIn=self.flowsIn[0],
            flowOut=self.flowsOut[0],
            N=self._NWf(),
            geom=self.geomPlateWf,
            L=self.L,
            W=self.W)["dpF"]

    cpdef public double _dpFSf(self):
        """float: Frictional pressure drop of a secondary fluid channel [-]. Calculated using the relevant method of mcycle.methods.heat_transfer defined in config.methods."""
        method = self.config.lookupMethod(self.__class__.__name__, (self.geomPlateSf.__class__.__name__, "friction", self.phaseSf(), "sf"))
        return getattr(ht, method)(flowIn=self.flowsIn[1], flowOut=self.flowsOut[1], N=self._NSf(), geom=self.geomPlateSf, L=self.L, W=self.W)["dpF"]

    cpdef public double U(self):
        """float: Overall heat transfer coefficient of the unit [W/m^2.K]."""
        cdef double RWf = (1 / self._hWf() + self.RfWf) / self.ARatioWf / self._NWf()
        cdef double RSf = (1 / self._hSf() + self.RfSf) / self.ARatioSf / self._NSf()
        cdef double RPlate = self.tWall / (
            self.NWall - 2) / self.wall.k() / self.ARatioWall
        return (RWf + RSf + RPlate)**-1

    cpdef double _f_sizeUnitsHxUnitPlate(self, double value, str attr):
        self.update({attr: value})
        return self.Q() - self.Q_LMTD()
    
    cpdef public void sizeUnits(self, str attr, list bracket) except *:
        """Solves for the value of the nominated component attribute required to return the defined outgoing FlowState.

Parameters
-----------
attr : string, optional
    Attribute to be solved. If None, self.sizeAttr is used. Defaults to None.
bracket : float or list of float, optional
    Bracket containing solution of size(). If None, self.sizeBracket is used. Defaults to None.

    - if bracket=[a,b]: scipy.optimize.brentq is used.

    - if bracket=a or [a]: scipy.optimize.newton is used.
        """
        cdef double tol, sizedValue, fa, fb, r
        cdef list bracketOriginal
        if attr == '':
            attr = self.sizeAttr
        if bracket == []:
            bracket = self.sizeBracket
        bracketOriginal = bracket
        try:
            tol = self.config.tolAbs + self.config.tolRel * self.Q()
            if len(bracket) == 2:
                try:
                    sizedValue = opt.brentq(self._f_sizeUnitsHxUnitPlate,
                                            bracket[0],
                                            bracket[1],
                                            args=(attr),
                                            rtol=self.config.tolRel,
                                            xtol=self.config.tolAbs)
                except:
                    a = bracket[0]
                    b = bracket[1]
                    fa = self._f_sizeUnitsHxUnitPlate(a, attr)
                    fb = self._f_sizeUnitsHxUnitPlate(b, attr)
                    r = a - fa*(b-a)/(fb-fa)
                    try:
                        sizedValue = opt.brentq(self._f_sizeUnitsHxUnitPlate,
                                            a,
                                            2*r-a,
                                            args=(attr),
                                            rtol=self.config.tolRel,
                                            xtol=self.config.tolAbs)
                    except:
                        try:
                            sizedValue = opt.brentq(self._f_sizeUnitsHxUnitPlate,
                                            b,
                                            2*r-b,
                                            args=(attr),
                                            rtol=self.config.tolRel,
                                            xtol=self.config.tolAbs)
                        except Exception as exc:
                            warn('Could not find solution in brackets {} or {}.'.format([a, 2*r-a], [b, 2*r-b]))
                            raise exc
            elif len(bracket) == 1:
                sizedValue = opt.newton(self._f_sizeUnitsHxUnitPlate, bracket[0], tol=tol, args=(attr))
            else:
                raise ValueError("bracket is not valid (given: {})".format(bracket))
            self.update({attr: sizedValue})
            # return sizedValue
        except AssertionError as err:
            raise err
        except:
            raise Exception(
                "{}.sizeUnit({},{}) failed to converge".format(
                    self.__class__.__name__, attr, bracketOriginal))


    @property
    def geomPlate(self):
        if self.geomPlateSf is self.geomPlateWf:
            return self.geomPlateWf
        else:
            warn(
                "geomPlate is not valid: geomPlateWf and geomPlateSf are different objects"
            )
            pass

    @geomPlate.setter
    def geomPlate(self, obj):
        self.geomPlateWf = obj
        self.geomPlateSf = obj
    @property
    def plate(self):
        """alias of self.wall."""
        return self.wall

    @plate.setter
    def plate(self, value):
        self.wall = value

    @property
    def tPlate(self):
        """alias of self.tWall."""
        return self.tWall

    @tPlate.setter
    def tPlate(self, value):
        self.tWall = value

    @property
    def ARatioPlate(self):
        """alias of self.ARatioWall."""
        return self.ARatioWall

    @ARatioPlate.setter
    def ARatioPlate(self, value):
        self.ARatioWall = value

    @property
    def NPlate(self):
        """alias of self.NWall."""
        return self.NWall

    @NPlate.setter
    def NPlate(self, value):
        self.NWall = value