from .hx_basic cimport HxBasic
from .hxunit_basicplanar cimport HxUnitBasicPlanar
from .flowconfig cimport HxFlowConfig
from ...bases.config cimport Config
from ...bases.flowstate cimport FlowState
from ...bases.solidmaterial cimport SolidMaterial
from ..._constants cimport *
from ...logger import log
from math import nan
import scipy.optimize as opt
from cython.parallel import prange
cdef tuple _inputs = ('flowConfig', 'NWf', 'NSf', 'NWall', 'hWf_liq', 'hWf_tp', 'hWf_vap', 'hSf', 'RfWf', 'RfSf', 'wall', 'tWall', 'L', 'W', 'ARatioWf', 'ARatioSf', 'ARatioWall', 'efficiencyThermal', 'flowInWf', 'flowInSf', 'flowOutWf', 'flowOutSf', 'ambient', 'sizeAttr', 'sizeBounds', 'sizeUnitsBounds', 'runBounds', 'runUnitsBounds', 'name', 'notes', 'config')
cdef tuple _properties = ('mWf', 'mSf', 'Q()', 'A', 'dpWf()', 'dpSf()', 'isEvap()')
        
cdef class HxBasicPlanar(HxBasic):
    r"""Characterises a basic planar heat exchanger consisting of working fluid and secondary fluid flows separated by a solid wall with single-phase or multi-phase working fluid but only single-phase secondary fluid.

Parameters
----------
flowConfig : HxFlowConfig, optional
    Flow configuration/arrangement information. See :meth:`mcycle.bases.component.HxFlowConfig`.
NWf : int, optional
    Number of parallel working fluid channels [-]. Defaults to 1.
NSf : int, optional
    Number of parallel secondary fluid channels [-]. Defaults to 1.
NWall : int, optional
    Number of parallel walls [-]. Defaults to 1.
hWf_liq : float, optional
    Heat transfer coefficient of the working fluid in the single-phase liquid region (subcooled). Defaults to nan.
hWf_tp : float, optional
    Heat transfer coefficient of the working fluid in the two-phase liquid/vapour region. Defaults to nan.
hWf_vap : float, optional
    Heat transfer coefficient of the working fluid in the single-phase vapour region (superheated). Defaults to nan.
hSf : float, optional
    Heat transfer coefficient of the secondary fluid in a single-phase region. Defaults to nan.
RfWf : float, optional
    Thermal resistance due to fouling on the working fluid side. Defaults to 0.
RfSf : float, optional
    Thermal resistance due to fouling on the secondary fluid side. Defaults to 0.
wall : SolidMaterial, optional
    Wall material. Defaults to None.
tWall : float, optional
    Thickness of the wall [m]. Defaults to nan.
L : float, optional
    Length of the heat transfer surface area (dimension parallel to flow direction) [m]. Defaults to nan.
W : float, optional
    Width of the heat transfer surface area (dimension perpendicular to flow direction) [m]. Defaults to nan.
ARatioWf : float, optional
    Multiplier for the heat transfer surface area of the working fluid [-]. Defaults to 1.
ARatioSf : float, optional
    Multiplier for the heat transfer surface area of the secondary fluid [-]. Defaults to 1.
ARatioWall : float, optional
    Multiplier for the heat transfer surface area of the wall [-]. Defaults to 1.
efficiencyThermal : float, optional
    Thermal efficiency [-]. Defaults to 1.
flowInWf : FlowState, optional
    Incoming FlowState of the working fluid. Defaults to None.
flowInSf : FlowState, optional
    Incoming FlowState of the secondary fluid. Defaults to None.
flowOutWf : FlowState, optional
    Outgoing FlowState of the working fluid. Defaults to None.
flowOutSf : FlowState, optional
    Outgoing FlowState of the secondary fluid. Defaults to None.
ambient : FlowState, optional
    Ambient environment flow state. Defaults to None.
sizeAttr : string, optional
    Default attribute used by size(). Defaults to "N".
sizeBounds : float or list of float, optional
    Bracket containing solution of size(). Defaults to [1, 100].
sizeUnitsBounds : float or list of float, optional
    Bracket passed on to any HxUnits containing solution of size() for the unit. Typically this bounds is used to size for the length of the HxUnit. Defaults to [1e-5, 1.].
name : string, optional
    Description of object. Defaults to "HxBasicPlanar instance".
notes : string, optional
    Additional notes on the component such as model numbers. Defaults to "No notes/model info.".config : Config, optional
    Configuration parameters. Defaults to None which sets it to :meth:`defaults.CONFIG <mcycle.defaults.CONFIG>`.
    """

    def __init__(self,
                 HxFlowConfig flowConfig=HxFlowConfig(),
                 unsigned int NWf=1,
                 unsigned int NSf=1,
                 unsigned int NWall=1,
                 hWf_liq=nan,
                 hWf_tp=nan,
                 hWf_vap=nan,
                 double hSf=nan,
                 double RfWf=0,
                 double RfSf=0,
                 SolidMaterial wall=None,
                 double tWall=nan,
                 double L=nan,
                 double W=nan,
                 double ARatioWf=1,
                 double ARatioSf=1,
                 double ARatioWall=1,
                 double efficiencyThermal=1.0,
                 FlowState flowInWf=None,
                 FlowState flowInSf=None,
                 FlowState flowOutWf=None,
                 FlowState flowOutSf=None,
                 FlowState ambient=None,
                 str sizeAttr="NPlate",
                 list sizeBounds=[1, 100],
                 list sizeUnitsBounds=[1e-5, 1.],
                 runBounds = [nan, nan],
                 runUnitsBounds = [nan, nan],
                 str name="HxBasic instance",
                 str notes="No notes/model info.",
                 Config config=None,
                 _unitClass=HxUnitBasicPlanar):
        self.L = L
        self.W = W
        super().__init__(flowConfig, NWf, NSf, NWall, hWf_liq, hWf_tp, hWf_vap,
                         hSf, RfWf, RfSf, wall, tWall, L * W, ARatioWf,
                         ARatioSf, ARatioWall, efficiencyThermal, flowInWf, flowInSf,
                         flowOutWf, flowOutSf, ambient, sizeAttr,
                         sizeBounds, sizeUnitsBounds, runBounds, runUnitsBounds, name, notes, config, _unitClass)
        self._units = []
        self._unitClass = HxUnitBasicPlanar
        if self.hasInAndOut(0) and self.hasInAndOut(1):
            pass  # self._unitise()
        self._inputs = _inputs
        self._properties = _properties

    cpdef public double _A(self):
        return self.L * self.W

    cdef public tuple _unitArgsLiq(self):
        """Arguments passed to HxUnits in the liquid region."""
        return (self.flowConfig, self.NWf, self.NSf, self.NWall, self.hWf_liq,
                self.hSf, self.RfWf, self.RfSf, self.wall, self.tWall, None,
                self.W, self.ARatioWf, self.ARatioSf, self.ARatioWall,
                self.efficiencyThermal)

    cdef public tuple _unitArgsTp(self):
        """Arguments passed to HxUnits in the two-phase region."""
        return (self.flowConfig, self.NWf, self.NSf, self.NWall, self.hWf_tp,
                self.hSf, self.RfWf, self.RfSf, self.wall, self.tWall, None,
                self.W, self.ARatioWf, self.ARatioSf, self.ARatioWall,
                self.efficiencyThermal)

    cdef public tuple _unitArgsVap(self):
        """Arguments passed to HxUnits in the vapour region."""
        return (self.flowConfig, self.NWf, self.NSf, self.NWall, self.hWf_vap,
                self.hSf, self.RfWf, self.RfSf, self.wall, self.tWall, None,
                self.W, self.ARatioWf, self.ARatioSf, self.ARatioWall,
                self.efficiencyThermal)

    cpdef public double size_L(self):
        """float: Solve for the required length of the Hx to satisfy the heat transfer equations [m]."""
        cdef double L = 0.
        cdef HxUnitBasicPlanar unit
        cdef size_t i
        for i in range(len(self._units)):#unit in self._units:
            unit = self._units[i]
            if abs(unit.Q()) > self.config.tolAbs:
                unit.sizeUnits()
                L += unit.L
        self.L = L
        return L


    cpdef double _f_sizeHxBasicPlanar(self, double value, double L, str attr):
        self.update({attr: value})
        return self.size_L() - L
                        
    cpdef public void size(self) except *:
        """Solves for the value of the nominated component attribute required to return the defined outgoing FlowState.
        """
        cdef double L, tol
        cdef HxUnitBasicPlanar unit
        cdef str attr = self.sizeAttr
        cdef list bounds = self.sizeBounds
        cdef list unitsBounds = self.sizeUnitsBounds
        try:
            if attr == "L":
                self.size_L()
            elif attr == "flowOutSf":
                super(HxBasicPlanar, self).size()
            else:
                # self.unitise()
                L = self.L
                tol = self.config.tolAbs + self.config.tolRel * abs(self.Q())
                if len(bounds) == 2:
                    sizedValue = opt.brentq(
                        self._f_sizeHxBasicPlanar,
                        bounds[0],
                        bounds[1],
                        args=(L, attr),
                        rtol=self.config.tolRel,
                        xtol=self.config.tolAbs)
                elif len(bounds) == 1:
                    sizedValue = opt.newton(self._f_sizeHxBasicPlanar, bounds[0], args=(L, attr), tol=tol)
                else:
                    raise ValueError("HxBasicPlanar.size(): bounds are not valid (given: {})".format(bounds))
                self.update({attr: sizedValue})
                #return sizedValue
        except Exception as exc:
            msg = 'HxPlate.size(): failed to converge.'
            log('error', msg, exc)
            raise exc


    cpdef double _f_runHxBasicPlanar(self, double value, double saveL):
        self.flowsOut[0] = self.flowsIn[0].copyUpdateState(HmassP_INPUTS, value, self.flowsIn[0].p())
        cdef double hOut = self.flowsIn[1].h() - self._mWf() * self._efficiencyFactorWf() * (self.flowsOut[0].h() - self.flowsIn[0].h()) / self._mSf() / self._efficiencyFactorSf()
        self.flowsOut[1] = self.flowsIn[1].copyUpdateState(HmassP_INPUTS, hOut, self.flowsIn[1].p())
        self.unitise()
        o = saveL - self.size_L()
        #print("----------- _f_runHxBasicPlanar, saveL - self.size_L = ", o)
        return o
        
    cpdef public void run(self):
        cdef double tol, sizedValue, a, b, saveL = self.L
        """
        cdef FlowState critWf = self.flowsIn[0].copyUpdateState(PT_INPUTS, self.flowsIn[0].p(), self.flowsIn[0]._state.T_critical())
        cdef FlowState minWf = self.flowsIn[0].copyUpdateState(PT_INPUTS, self.flowsIn[0].p(), self.flowsIn[0]._state.Tmin())
        cdef double deltah"""
        try:
            """
            if self.isEvap():
                deltah = critWf.h() - self.flowsIn[0].h()
                a = self.flowsIn[0].h() + deltah*self.runBounds[0]
                if self.flowsIn[1].T() > critWf.T():
                    b = self.flowsIn[0].h() + deltah*self.runBounds[1]
                else:
                    deltah = self.flowsIn[0].copyUpdateState(PT_INPUTS, self.flowsIn[0].p(), self.flowsIn[1].T()).h() - self.flowsIn[0].h()
                    b = self.flowsIn[0].h() + deltah*(self.runBounds[1])
            else:
                deltah = self.flowsIn[0].h() - minWf.h()
                b = self.flowsIn[0].h() - deltah*self.runBounds[0]
                
                if self.flowsIn[1].T() < minWf.T():
                    a = self.flowsIn[0].h() - deltah*self.runBounds[1]
                else:
                    deltah = self.flowsIn[0].h() - self.flowsIn[0].copyUpdateState(PT_INPUTS, self.flowsIn[0].p(), self.flowsIn[1].T()).h()
                    a = self.flowsIn[0].h() - deltah*self.runBounds[1]
           
            sizedValue = opt.brentq(self._f_runHxBasicPlanar,
                                    a,
                                    b,
                                    args=(saveL),
                                    rtol=self.config.tolRel,
                                    xtol=self.config.tolAbs)
            """
            sizedValue = opt.brentq(self._f_runHxBasicPlanar,
                                    *self.runBounds,
                                    args=(saveL),
                                    rtol=self.config.tolRel,
                                    xtol=self.config.tolAbs)
        except AssertionError as err:
            raise err
        except AttributeError as err:
            raise err
        except Exception as exc:
            raise StopIteration(
                "{}.run() failed to converge. Check bounds for solution: runBounds={}. ".format(
                    self.__class__.__name__, self.runBounds), exc)
        finally:
            
            self.update({"L": saveL})

            
    @property
    def A(self):
        """float: Heat transfer surface area. A = L * W.
        Setter preserves the ratio of L/W."""
        return self.L * self.W

    @A.setter
    def A(self, value):
        if self.L and self.W:
            a = self.L * self.W
            self.L *= (value / a)**0.5
            self.W *= (value / a)**0.5
        else:
            pass

