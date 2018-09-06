from .mcabstractbase cimport MCAttr
from .flowstate cimport FlowState
from ..DEFAULTS cimport COOLPROP_EOS
from ..logger import log
import CoolProp as CP
from math import nan, isnan
import numpy as np

cdef dict _validInputPairs
_validInputPairs = {'T': CP.PT_INPUTS, 'rho': CP.DmassP_INPUTS, 'h': CP.HmassP_INPUTS, 's': CP.PSmass_INPUTS}
        
cdef class FlowStatePoly(FlowState):
    """FlowStatePoly represents the state of a flow at a point by its state properties and a mass flow rate. It is an alternative to FlowState that uses polynomial interpolation of a crude constant pressure reference data map to evaluate the state properties, instead of calling them from a CoolProp AbstractState object. This class was created purely to overcome short comings with CoolProp's mixture processes. Apart from creating new objects, FlowStatePoly has been built to be used in exactly the same way as FlowState.

.. note:: FlowStatePoly only supports constant pressure flows and assumes no phase changes occur.
   It may not be used for the working fluid in a cycle, but may be used as the working fluid in certain constant pressure components.

Parameters
----------
refData : RefData
    Constant pressure fluid reference data map.

m : double, optional
    Mass flow rate [Kg/s]. Defaults to nan.

inputPairCP : int, optional
    CoolProp input pair key. See `documentation <http://www.coolprop.org/_static/doxygen/html/namespace_cool_prop.html#a58e7d98861406dedb48e07f551a61efb>`_. Eg. CoolProp.HmassP_INPUTS. Defaults to INPUT_PAIR_INVALID == 0.

    .. note:: Only certain inputPairCP values are valid.
        As FlowStatePoly only supports constant pressure flows, one input variable must be a pressure. Thus, only the following inputPairCP values are valid:

        - CoolProp.PT_INPUTS == 9
        - CoolProp.DmassP_INPUTS == 18
        - CoolProp.HmassP_INPUTS == 20
        - CoolProp.PSmass_INPUTS == 22

input1,input2 : double, optional
    Repective values of inputs corresponding to inputPairCP [in SI units]. Both default to nan.


Examples
----------
>>> refData = RefData("air", 2, 101325., [200, 250, 300, 350, 400])
>>> air = FlowStatePoly(refData, 1, CoolProp.PT_INPUTS,101325.,293.15)
>>> air.rho
1.20530995019
>>> air.cp
1006.12622976
    """

    def __init__(self,
                  RefData refData,
                  double m=nan,
                  int inputPairCP=0,
                  double input1=nan,
                  double input2=nan,
                  str name="FlowStatePoly instance"):
        self.refData = refData
        self.fluid = refData.fluid
        self.phaseCP = refData.phaseCP
        self.m = m
        self._inputPairCP = inputPairCP
        self._input1 = input1
        self._input2 = input2
        self.name = name
        self._c = {}
        self._inputProperty = ''
        self._inputValue = nan
        self._validateInputs()
        self._inputs = {"refData": MCAttr(RefData, "none"), "m": MCAttr(float, "mass/time"),
                "_inputPairCP": MCAttr(int, "none"), "_input1": MCAttr(float, "none"),
                        "_input2": MCAttr(float, "none"), "name": MCAttr(str, "none")}
        self._properties = {"T()": MCAttr(float, "temperature"), "p()": MCAttr(float, "pressure"), "rho()": MCAttr(float, "density"),
                "h()": MCAttr(float, "energy/mass"), "s()": MCAttr(float, "energy/mass-temperature"),
                "cp()": MCAttr(float, "energy/mass-temperature"), "visc()": MCAttr(float, "force-time/area"),
                "k()": MCAttr(float, "power/length-temperature"), "Pr()": MCAttr(float, "none"),
                "x()": MCAttr(float, "none")}

        
    cpdef public FlowState copyState(self, int inputPairCP, double input1, double input2):
        """Creates a new copy of a FlowState object. As a shortcut, args can be passed to update the object copy (see update()).

Parameters
----------
inputPairCP : int, optional
    CoolProp input pair key. See `documentation <http://www.coolprop.org/_static/doxygen/html/namespace_cool_prop.html#a58e7d98861406dedb48e07f551a61efb>`_. Eg. CoolProp.HmassP_INPUTS. Defaults to None.

input1, input2 : double, optional
    Repective values of inputs corresponding to inputPairCP [in SI units]. Both default to None.
        """
        if inputPairCP == 0 or isnan(input1) or isnan(input2):
            return FlowStatePoly(*self._inputValues())
        else:
            return FlowStatePoly(self.refData, self.m, inputPairCP, input1, input2)
      
    cpdef public void updateState(self, int inputPairCP, double input1, double input2):
        """void: Calls CoolProp's AbstractState.update function.

Parameters
----------
inputPairCP : int, optional
    CoolProp input pair key. See `documentation <http://www.coolprop.org/_static/doxygen/html/namespace_cool_prop.html#a58e7d98861406dedb48e07f551a61efb>`_. Eg. CoolProp.HmassP_INPUTS.

input1,input2 : double
    Repective values of inputs corresponding to inputPairCP [in SI units]. One input must be equal to the pressure of refData. Both default to None.
"""
        self._inputPairCP = inputPairCP
        self._input1 = input1
        self._input2 = input2
        self._validateInputs()

    cdef void _findAndSetInputProperty(self):
        """str : Return string of input property that is not pressure."""
        self._inputProperty = list(_validInputPairs.keys())[list(_validInputPairs.values()).index(self._inputPairCP)]
    
    cdef bint _validateInputs(self) except? False:
        """bint: Validate inputs and call _findAndSetInputProperty."""
        if self._inputPairCP != -1:
            if self._inputPairCP in _validInputPairs.values():
                if self._inputPairCP is CP.PT_INPUTS or self._inputPairCP is CP.PSmass_INPUTS:
                    if self._input1 == self.refData.p:
                        self._inputValue = self._input2
                        self._findAndSetInputProperty()
                        if self.refData.deg >= 0:
                            self.populate_c()
                        return True
                    else:
                        raise ValueError(
                            """Input pressure does not match reference data pressure: {} != {}""".format(self._input1, self.refData.p))
                elif self._input2 == self.refData.p:
                    self._inputValue = self._input1
                    self._findAndSetInputProperty()
                    if self.refData.deg >= 0:
                        self.populate_c()
                    return True
                else:
                    raise ValueError(
                        "Input pressure does not match reference data pressure: {} != {}".
                        format(self._input2, self.refdata.p))
            else:
                raise ValueError(
                    """{0} is not a valid input pair for FlowStatePoly
                Select from PT_INPUTS=9, DmassP_INPUTS=18, HmassP_INPUTS=20, PSmass_INPUTS=22""".format(self._inputPairCP))
        else:
            return False

    cpdef public void populate_c(self):
        self._c = {}
        cdef str key
        for key in self.refData.data.keys():
            self._c[key] = list(
                    np.polyfit(self.refData.data[self._inputProperty], self.refData.data[key], self.refData.deg))


    cpdef public double p(self):
        """double: Static pressure [Pa]."""
        return self.refData.p

    cpdef public double T(self):
        "double: Static temperture [K]."
        if self.refData.deg == -1:
            return np.interp(self._inputValue, self.refData.data[self._inputProperty], self.refData.data['T'])
        else:
            return np.polyval(self._c['T'], self._inputValue)

    cpdef public double h(self):
        """double: Specific mass enthalpy [J/Kg]."""
        if self.refData.deg == -1:
            return np.interp(self._inputValue, self.refData.data[self._inputProperty], self.refData.data['h'])
        else:
            return np.polyval(self._c['h'], self._inputValue)

    cpdef public double rho(self):
        """double: Mass density [Kg/m^3]."""
        if self.refData.deg == -1:
            return np.interp(self._inputValue, self.refData.data[self._inputProperty], self.refData.data['rho'])
        else:
            return np.polyval(self._c['rho'], self._inputValue)

    cpdef public double s(self):
        """double: Specific mass entropy [J/Kg.K]."""
        if self.refData.deg == -1:
            return np.interp(self._inputValue, self.refData.data[self._inputProperty], self.refData.data['s'])
        else:
            return np.polyval(self._c['s'], self._inputValue)

    cpdef public double visc(self):
        """double: Dynamic viscosity [N.s/m^2]."""
        if self.refData.deg == -1:
            return np.interp(self._inputValue, self.refData.data[self._inputProperty], self.refData.data['visc'])
        else:
            return np.polyval(self._c['visc'], self._inputValue)

    cpdef public double k(self):
        """double: Thermal conductivity [W/m.K]."""
        if self.refData.deg == -1:
            return np.interp(self._inputValue, self.refData.data[self._inputProperty], self.refData.data['k'])
        else:
            return np.polyval(self._c['k'], self._inputValue)

    cpdef public double cp(self):
        """double: Specific mass heat capacity, const. pressure [J/K]."""
        if self.refData.deg == -1:
            return np.interp(self._inputValue, self.refData.data[self._inputProperty], self.refData.data['cp'])
        else:
            return np.polyval(self._c['cp'], self._inputValue)

    cpdef public double Pr(self):
        """double: Prandtl number [-]."""
        if self.refData.deg == -1:
            return np.interp(self._inputValue, self.refData.data[self._inputProperty], self.refData.data['Pr'])
        else:
            return np.polyval(self._c['Pr'], self._inputValue)

    cpdef public double x(self):
        """double: Quality [-]. By definition, x = -1 for all FlowStatePoly objects."""
        return -1
    
    cpdef public double pCrit(self):
        r"""double: Critical pressure [Pa]."""
        log("warning", "FlowStatePoly, critical pressure is not defined for mixtures")
        return nan
    
    cpdef public double pMin(self):
        r"""double: Minimum pressure [Pa]."""
        log("warning", "FlowStatePoly, minimum pressure is not defined for mixtures")
        return nan
    
    cpdef public double TCrit(self):
        r"""double: Critical temperture [K]."""
        log("warning", "FlowStatePoly, critical temperature is not defined for mixtures")
        return nan
    
    cpdef public double TMin(self):
        r"""double: Minimum temperture [K]."""
        log("warning", "FlowStatePoly, minimum temperature is not defined for mixtures")
        return nan

    cpdef public str phase(self):
        """str: identifier of phase; 'liq':subcooled liquid, 'vap':superheated vapour, 'sp': unknown single-phase."""
        cdef double liq_h = 0
        try:
            liq_h = CP.CoolProp.PropsSI("HMASS", "P", self.refData.p, "Q", 0,
                                        self.refData.fluid)
            if self.h() < liq_h:
                return "liq"
            else:
                return "vap"
        except ValueError:
            return "sp"


cdef class RefData:
    """cdef class. RefData stores constant pressure thermodynamic properties of a 'pure' fluid or mixture thereof. Property data can be directly input, or, if only temperature data is provided, RefData will call CoolProp to compute the remaining properties.

Parameters
----------
fluid : str
    Description of fluid passed to CoolProp.

    - "fluid_name" for pure fluid. Eg, "air", "water", "CO2" *or*

    - "fluid0[mole_fraction0]&fluid1[mole_fraction1]&..." for mixtures. Eg, "CO2[0.5]&CO[0.5]".

    .. note:: CoolProp's mixture routines often raise errors; using mixtures should be avoided.


deg : int
    Polynomial degree used to fit the data using `numpy.polyfit <https://docs.scipy.org/doc/numpy-1.14.0/reference/generated/numpy.polyfit.html>`_. If -1, properties will be linearly interpolated between the data values using `numpy.interp <https://docs.scipy.org/doc/numpy-1.14.0/reference/generated/numpy.interp.html>`_.

p: double
    Constant static pressure [Pa] of the property data.

data : dict
    Dictionary of data map values. Data must be given as a list of floats for each of the following keys:
    
    - 'T' : static temperature [K].
    - 'h' : specific mass enthalpy [J/Kg].
    - 'rho' : mass density [Kg/m^3].
    - 's' : specific mass entropy [J/Kg.K].
    - 'visc' : dynamic viscosity [N.s/m^2].
    - 'k' : thermal conductivity [W/m.K].
    - 'cp' : specific mass heat capacity, const. pressure [J/K].
    - 'Pr' : Prandtl number.

    A complete map must be provided or if only temperature values are provided, MCycle will attempt to populate the data using CoolProp.

phaseCP : int, optional
    Coolprop key for phase. See `documentation <http://www.coolprop.org/_static/doxygen/html/namespace_cool_prop.html#a99d892f7b3bb9808265335ac1efb858f>`_. Eg, CoolProp.iphase_gas. Defaults to -1.
    """

    def __init__(self,
                  str fluid,
                  int deg,
                  double p,
                  dict data,
                  int phaseCP=-1):
        self.fluid = fluid
        self.phaseCP = phaseCP
        self.deg = deg
        self.p = p
        assert data['T'] != [], "Temperature data (key='T') must be provided at a minimum."
        self.data = {'T': data['T'], 'h': [], 'rho': [], 's': [], 'visc': [], 'k': [], 'cp': [], 'Pr': []}     
        cdef list other_props = ['h', 'rho', 's', 'visc', 'k', 'cp', 'Pr']
        cdef str prop
        cdef size_t lenDataT = len(data['T'])
        if data.keys() == self.data.keys():
            if all(data[prop] == [] for prop in other_props):
                self.populateData()
            elif not all(len(data[prop]) == lenDataT for prop in other_props):
                raise ValueError(
                    "Not all data lists have same length as data['T']: len={}".format(lenDataT))
            else:
                self.data = data
        else:
            self.populateData()

    cpdef public void populateData(self) except *:
        """void: Populate property data list from data['T'] using CoolProp."""
        if self.data['T'] == []:
            raise ValueError("data['T'] must not be empty.")
        cdef list other_props = ['h', 'rho', 's', 'visc', 'k', 'cp', 'Pr']
        cdef str prop
        for prop in other_props:
            self.data[prop] = []
        cdef double T
        cdef FlowState f
        for T in self.data['T']:
            f = FlowState(self.fluid, self.phaseCP, nan,
                          CP.PT_INPUTS, self.p, T)
            for prop in other_props:
                self.data[prop].append(getattr(f, prop)())
