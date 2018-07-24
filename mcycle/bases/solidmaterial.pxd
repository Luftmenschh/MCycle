from .mcabstractbase cimport MCAB

cdef class SolidMaterial(MCAB):
    cpdef public double rho
    cpdef public dict data
    cdef dict _c
    cpdef public int deg
    cpdef public double T
    cpdef public str notes

    cpdef public void populate_c(self)
    cpdef public double k(self)
    
    
