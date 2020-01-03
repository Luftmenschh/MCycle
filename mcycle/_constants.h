/* Generated by Cython 0.28.6 */

#ifndef __PYX_HAVE__mcycle___constants
#define __PYX_HAVE__mcycle___constants


#ifndef __PYX_HAVE_API__mcycle___constants

#ifndef __PYX_EXTERN_C
  #ifdef __cplusplus
    #define __PYX_EXTERN_C extern "C"
  #else
    #define __PYX_EXTERN_C extern
  #endif
#endif

#ifndef DL_IMPORT
  #define DL_IMPORT(_T) _T
#endif

__PYX_EXTERN_C double TOLABS_X;
__PYX_EXTERN_C unsigned char INPUT_PAIR_INVALID;
__PYX_EXTERN_C unsigned char QT_INPUTS;
__PYX_EXTERN_C unsigned char PQ_INPUTS;
__PYX_EXTERN_C unsigned char QSmolar_INPUTS;
__PYX_EXTERN_C unsigned char QSmass_INPUTS;
__PYX_EXTERN_C unsigned char HmolarQ_INPUTS;
__PYX_EXTERN_C unsigned char HmassQ_INPUTS;
__PYX_EXTERN_C unsigned char DmolarQ_INPUTS;
__PYX_EXTERN_C unsigned char DmassQ_INPUTS;
__PYX_EXTERN_C unsigned char PT_INPUTS;
__PYX_EXTERN_C unsigned char DmassT_INPUTS;
__PYX_EXTERN_C unsigned char DmolarT_INPUTS;
__PYX_EXTERN_C unsigned char HmolarT_INPUTS;
__PYX_EXTERN_C unsigned char HmassT_INPUTS;
__PYX_EXTERN_C unsigned char SmolarT_INPUTS;
__PYX_EXTERN_C unsigned char SmassT_INPUTS;
__PYX_EXTERN_C unsigned char TUmolar_INPUTS;
__PYX_EXTERN_C unsigned char TUmass_INPUTS;
__PYX_EXTERN_C unsigned char DmassP_INPUTS;
__PYX_EXTERN_C unsigned char DmolarP_INPUTS;
__PYX_EXTERN_C unsigned char HmassP_INPUTS;
__PYX_EXTERN_C unsigned char HmolarP_INPUTS;
__PYX_EXTERN_C unsigned char PSmass_INPUTS;
__PYX_EXTERN_C unsigned char PSmolar_INPUTS;
__PYX_EXTERN_C unsigned char PUmass_INPUTS;
__PYX_EXTERN_C unsigned char PUmolar_INPUTS;
__PYX_EXTERN_C unsigned char HmassSmass_INPUTS;
__PYX_EXTERN_C unsigned char HmolarSmolar_INPUTS;
__PYX_EXTERN_C unsigned char SmassUmass_INPUTS;
__PYX_EXTERN_C unsigned char SmolarUmolar_INPUTS;
__PYX_EXTERN_C unsigned char DmassHmass_INPUTS;
__PYX_EXTERN_C unsigned char DmolarHmolar_INPUTS;
__PYX_EXTERN_C unsigned char DmassSmass_INPUTS;
__PYX_EXTERN_C unsigned char DmolarSmolar_INPUTS;
__PYX_EXTERN_C unsigned char DmassUmass_INPUTS;
__PYX_EXTERN_C unsigned char DmolarUmolar_INPUTS;
__PYX_EXTERN_C unsigned char iphase_liquid;
__PYX_EXTERN_C unsigned char iphase_supercritical;
__PYX_EXTERN_C unsigned char iphase_supercritical_gas;
__PYX_EXTERN_C unsigned char iphase_supercritical_liquid;
__PYX_EXTERN_C unsigned char iphase_critical_point;
__PYX_EXTERN_C unsigned char iphase_gas;
__PYX_EXTERN_C unsigned char iphase_twophase;
__PYX_EXTERN_C unsigned char iphase_unknown;
__PYX_EXTERN_C unsigned char iphase_not_imposed;
__PYX_EXTERN_C unsigned char PHASE_LIQUID;
__PYX_EXTERN_C unsigned char PHASE_SUPERCRITICAL;
__PYX_EXTERN_C unsigned char PHASE_SUPERCRITICAL_GAS;
__PYX_EXTERN_C unsigned char PHASE_SUPERCRITICAL_LIQUID;
__PYX_EXTERN_C unsigned char PHASE_CRITICAL_POINT;
__PYX_EXTERN_C unsigned char PHASE_VAPOUR;
__PYX_EXTERN_C unsigned char PHASE_VAPOR;
__PYX_EXTERN_C unsigned char PHASE_GAS;
__PYX_EXTERN_C unsigned char PHASE_TWOPHASE;
__PYX_EXTERN_C unsigned char PHASE_UNKNOWN;
__PYX_EXTERN_C unsigned char PHASE_NOT_IMPOSED;
__PYX_EXTERN_C unsigned char PHASE_SATURATED_LIQUID;
__PYX_EXTERN_C unsigned char PHASE_SATURATED_VAPOUR;
__PYX_EXTERN_C unsigned char PHASE_SATURATED_VAPOR;
__PYX_EXTERN_C unsigned char UNITPHASE_NONE;
__PYX_EXTERN_C unsigned char UNITPHASE_ALL;
__PYX_EXTERN_C unsigned char UNITPHASE_LIQUID;
__PYX_EXTERN_C unsigned char UNITPHASE_VAPOUR;
__PYX_EXTERN_C unsigned char UNITPHASE_VAPOR;
__PYX_EXTERN_C unsigned char UNITPHASE_GAS;
__PYX_EXTERN_C unsigned char UNITPHASE_TWOPHASE_EVAPORATING;
__PYX_EXTERN_C unsigned char UNITPHASE_TP_EVAP;
__PYX_EXTERN_C unsigned char UNITPHASE_TWOPHASE_CONDENSING;
__PYX_EXTERN_C unsigned char UNITPHASE_TP_COND;
__PYX_EXTERN_C unsigned char UNITPHASE_SUPERCRITICAL;
__PYX_EXTERN_C unsigned char UNITPHASE_ALL_SINGLEPHASE;
__PYX_EXTERN_C unsigned char UNITPHASE_ALL_SP;
__PYX_EXTERN_C unsigned char UNITPHASE_ALL_TWOPHASE;
__PYX_EXTERN_C unsigned char UNITPHASE_ALL_TP;
__PYX_EXTERN_C unsigned char TRANSFER_NONE;
__PYX_EXTERN_C unsigned char TRANSFER_ALL;
__PYX_EXTERN_C unsigned char TRANSFER_HEAT;
__PYX_EXTERN_C unsigned char TRANSFER_FRICTION;
__PYX_EXTERN_C unsigned char FLOW_NONE;
__PYX_EXTERN_C unsigned char FLOW_ALL;
__PYX_EXTERN_C unsigned char WORKING_FLUID;
__PYX_EXTERN_C unsigned char FLOW_PRIMARY;
__PYX_EXTERN_C unsigned char SECONDARY_FLUID;
__PYX_EXTERN_C unsigned char FLOW_SECONDARY;
__PYX_EXTERN_C unsigned char FLOWSENSE_UNDEFINED;
__PYX_EXTERN_C unsigned char COUNTERFLOW;
__PYX_EXTERN_C unsigned char PARALLELFLOW;
__PYX_EXTERN_C unsigned char CROSSFLOW;
__PYX_EXTERN_C PyObject *SOURCE_URL;
__PYX_EXTERN_C PyObject *DOCS_URL;

#endif /* !__PYX_HAVE_API__mcycle___constants */

/* WARNING: the interface of the module init function changed in CPython 3.5. */
/* It now returns a PyModuleDef instance instead of a PyModule instance. */

#if PY_MAJOR_VERSION < 3
PyMODINIT_FUNC init_constants(void);
#else
PyMODINIT_FUNC PyInit__constants(void);
#endif

#endif /* !__PYX_HAVE__mcycle___constants */
