# cython: embedsignature=True, cdivision=True

###############################################################################
#                                                                             #
# RMG - Reaction Mechanism Generator                                          #
#                                                                             #
# Copyright (c) 2002-2019 Prof. William H. Green (whgreen@mit.edu),           #
# Prof. Richard H. West (r.west@neu.edu) and the RMG Team (rmg_dev@mit.edu)   #
#                                                                             #
# Permission is hereby granted, free of charge, to any person obtaining a     #
# copy of this software and associated documentation files (the 'Software'),  #
# to deal in the Software without restriction, including without limitation   #
# the rights to use, copy, modify, merge, publish, distribute, sublicense,    #
# and/or sell copies of the Software, and to permit persons to whom the       #
# Software is furnished to do so, subject to the following conditions:        #
#                                                                             #
# The above copyright notice and this permission notice shall be included in  #
# all copies or substantial portions of the Software.                         #
#                                                                             #
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR  #
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,    #
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE #
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER      #
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING     #
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER         #
# DEALINGS IN THE SOFTWARE.                                                   #
#                                                                             #
###############################################################################

"""
This module contains classes that represent various models of translational
motion. Translational energies are much smaller than :math:`k_\\mathrm{B} T`
except for temperatures approaching absolute zero, so a classical treatment of
translation is more than adequate.
"""

import numpy as np
cimport numpy as np
from libc.math cimport log, sqrt

cimport rmgpy.constants as constants
import rmgpy.quantity as quantity
import rmgpy.statmech.schrodinger as schrodinger
cimport rmgpy.statmech.schrodinger as schrodinger

################################################################################


cdef class Translation(Mode):
    """
    A base class for all vibrational degrees of freedom. The attributes are:
    
    ======================== ===================================================
    Attribute                Description
    ======================== ===================================================
    `quantum`                ``True`` to use the quantum mechanical model, ``False`` to use the classical model
    ======================== ===================================================

    In the majority of chemical applications, the translational energy levels are
    much smaller than :math:`k_\\mathrm{B} T`, which makes a classical
    mechanical treatment adequate.
    """

    def __init__(self, quantum=True):
        Mode.__init__(self, quantum)

################################################################################


cdef class IdealGasTranslation(Translation):
    """
    A statistical mechanical model of translation in an 3-dimensional infinite
    square well by an ideal gas. The attributes are:
    
    =============== ============================================================
    Attribute       Description
    =============== ============================================================
    `mass`          The mass of the translating object
    `quantum`       ``True`` to use the quantum mechanical model, ``False`` to use the classical model
    =============== ============================================================
    
    Translational energies are much smaller than :math:`k_\\mathrm{B} T` except
    for temperatures approaching absolute zero, so a classical treatment of
    translation is more than adequate.
    """

    def __init__(self, mass=None, quantum=False):
        Translation.__init__(self, quantum)
        self.mass = mass

    def __repr__(self):
        """
        Return a string representation that can be used to reconstruct the
        IdealGasTranslation object.
        """
        result = 'IdealGasTranslation(mass={0!r}'.format(self.mass)
        if self.quantum:
            result += ', quantum=True'
        result += ')'
        return result

    def __reduce__(self):
        """
        A helper function used when pickling an IdealGasTranslation object.
        """
        return (IdealGasTranslation, (self.mass, self.quantum))

    property mass:
        """The mass of the translating object."""
        def __get__(self):
            return self._mass
        def __set__(self, value):
            if isinstance(value, quantity.ScalarQuantity):
                self._mass = value
            else:
                self._mass = quantity.Mass(value)

    cpdef double get_partition_function(self, double T) except -1:
        """
        Return the value of the partition function :math:`Q(T)` at the
        specified temperature `T` in K.
        """
        cdef double Q, qt, mass
        if self.quantum:
            raise NotImplementedError('Quantum mechanical model not yet implemented for IdealGasTranslation.')
        else:
            mass = self._mass.value_si
            qt = ((2 * constants.pi * mass) / (constants.h ** 2)) ** 1.5 / 101325.  # assume P = 1 atm = 101325 Pa
            Q = qt * (constants.kB * T) ** 2.5
        return Q

    cpdef double get_heat_capacity(self, double T) except -100000000:
        """
        Return the heat capacity in J/mol*K for the degree of freedom at the
        specified temperature `T` in K.
        """
        cdef double Cv
        if self.quantum:
            raise NotImplementedError('Quantum mechanical model not yet implemented for IdealGasTranslation.')
        else:
            Cv = 2.5
        return Cv * constants.R

    cpdef double get_enthalpy(self, double T) except 100000000:
        """
        Return the enthalpy in J/mol for the degree of freedom at the
        specified temperature `T` in K.
        """
        cdef double H
        if self.quantum:
            raise NotImplementedError('Quantum mechanical model not yet implemented for IdealGasTranslation.')
        else:
            H = 2.5
        return H * constants.R * T

    cpdef double get_entropy(self, double T) except -100000000:
        """
        Return the entropy in J/mol*K for the degree of freedom at the
        specified temperature `T` in K.
        """
        cdef double S
        if self.quantum:
            raise NotImplementedError('Quantum mechanical model not yet implemented for IdealGasTranslation.')
        else:
            S = log(self.get_partition_function(T)) + 2.5
        return S * constants.R

    cpdef np.ndarray get_sum_of_states(self, np.ndarray e_list, np.ndarray sum_states_0=None):
        """
        Return the sum of states :math:`N(E)` at the specified energies `e_list`
        in J/mol above the ground state. If an initial sum of states 
        `sum_states_0` is given, the rotor sum of states will be convoluted into
        these states.
        """
        cdef double qt, mass
        cdef np.ndarray sum_states
        if self.quantum:
            raise NotImplementedError('Quantum mechanical model not yet implemented for IdealGasTranslation.')
        elif sum_states_0 is not None:
            sum_states = schrodinger.convolve(sum_states_0, self.get_density_of_states(e_list))
        else:
            mass = self._mass.value_si
            e_list = e_list / constants.Na
            qt = ((2 * constants.pi * mass) / (constants.h ** 2)) ** 1.5 / 101325.
            sum_states = qt * e_list ** 2.5 / (sqrt(constants.pi) * 15.0 / 8.0)
        return sum_states

    cpdef np.ndarray get_density_of_states(self, np.ndarray e_list, np.ndarray dens_states_0=None):
        """
        Return the density of states :math:`\\rho(E) \\ dE` at the specified
        energies `e_list` in J/mol above the ground state. If an initial density
        of states `dens_states_0` is given, the rotor density of states will be
        convoluted into these states.
        """
        cdef double qt, dE, mass
        cdef np.ndarray dens_states
        if self.quantum:
            raise NotImplementedError('Quantum mechanical model not yet implemented for IdealGasTranslation.')
        else:
            mass = self._mass.value_si
            e_list = e_list / constants.Na
            dE = e_list[1] - e_list[0]
            qt = ((2 * constants.pi * mass) / (constants.h ** 2)) ** 1.5 / 101325.
            dens_states = qt * e_list ** 1.5 / (sqrt(constants.pi) * 0.75) * dE
            if dens_states_0 is not None:
                dens_states = schrodinger.convolve(dens_states_0, dens_states)
        return dens_states
