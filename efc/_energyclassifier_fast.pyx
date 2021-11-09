import numpy as np
cimport cython

# cython: profile=True
# cython: linetrace=True
# cython: binding=True
# distutils: define_macros=CYTHON_TRACE_NOGIL=1

# @cython.cdivision(True)
def pair_freq(self):
    cdef int i, j, count, ai, aj
    cdef float psdcounts = self.pseudocounts
    cdef int max_bin = self.max_bin
    cdef int n_inst = self.X_.shape[0]
    cdef int n_attr = self.X_.shape[1]

    pairfreq = np.zeros((n_attr, max_bin, n_attr, max_bin),
                        dtype='float')

    cdef double [:, :, :, :] pairfreq_view = pairfreq
    cdef double [:, :] sitefreq_view = self.sitefreq_

    for i in range(n_attr):
        for j in range(n_attr):
            unique, counts = np.unique(self.X_[:, [i, j]],
                                        return_counts=True, axis=0)
            for (pair, count) in zip(unique, counts):
                pairfreq_view[i, pair[0], j, pair[1]] = count 

    pairfreq /= n_inst
    pairfreq = ((1 - psdcounts) * pairfreq
                + psdcounts / (max_bin**2))

    cdef double [:, :, :, :] pairfreq_new_view = pairfreq

    for i in range(n_attr):
        for ai in range(max_bin):
            for aj in range(max_bin):
                if (ai == aj):
                    pairfreq_new_view[i, ai, i, aj] = sitefreq_view[i, ai]
                else:
                    pairfreq_new_view[i, ai, i, aj] = 0.0
    
    return pairfreq



def coupling(self):
    cdef int i, j, ai, aj
    cdef int n_attr = self.sitefreq_.shape[0]
    cdef int max_bin = self.max_bin
    corr_matrix = np.empty((n_attr * (max_bin - 1),
                            n_attr * (max_bin - 1)), dtype='float')

    cdef double [:, :] corr_matrix_view = corr_matrix
    cdef double [:, :] sitefreq_view = self.sitefreq_
    cdef double [:, :, :, :] pairfreq_view = self.pairfreq_

    for i in range(n_attr):
        for j in range(n_attr):
            for ai in range(max_bin - 1):
                for aj in range(max_bin - 1):
                    corr_matrix_view[i * (max_bin - 1) + ai,
                                j * (max_bin - 1) + aj] = (pairfreq_view[i, ai, j, aj]
                                                                - sitefreq_view[i, ai]
                                                                * sitefreq_view[j, aj])

    inv_corr = np.linalg.inv(corr_matrix_view)
    return np.exp(np.negative(inv_corr))


def local_fields(self):
    cdef int i, ai, j, aj
    cdef int n_inst = self.sitefreq_.shape[0]
    cdef int max_bin = self.max_bin

    fields = np.empty((n_inst * (max_bin - 1)), dtype='double')

    cdef double [:] fields_view = fields
    cdef double [:, :] sitefreq_view = self.sitefreq_
    cdef double [:, :, :, :] pairfreq_view = self.pairfreq_
    cdef double [:, :] coupling_view = self.coupling_matrix_

    for i in range(n_inst):
        for ai in range(max_bin - 1):
            fields_view[i * (max_bin - 1) + ai] = (sitefreq_view[i, ai]
                                                    / sitefreq_view[i, max_bin - 1])
            for j in range(n_inst):
                for aj in range(max_bin - 1):
                    fields_view[i * (max_bin - 1) + ai] /= (
                        coupling_view[i * (max_bin - 1) + ai, j * (max_bin - 1) + aj]**sitefreq_view[j, aj])

    return fields


def compute_energy(self, X):
    cdef int n_inst = X.shape[0]
    cdef int n_attr = X.shape[1]
    cdef int i, j, k, j_value, k_value
    cdef double e
    cdef int max_bin = self.max_bin

    energies = np.empty(n_inst, dtype='float64')

    cdef long [:, :] X_view = X
    cdef double [:] energies_view = energies
    cdef double [:, :] coupling_view = self.coupling_matrix_
    cdef double [:] fields_view = self.local_fields_

    for i in range(n_inst):
        e = 0
        for j in range(n_attr - 1):
            j_value = X_view[i, j]
            if j_value != (max_bin - 1):
                for k in range(j, n_attr):
                    k_value = X_view[i, k]
                    if k_value != (max_bin - 1):
                        e -= (coupling_view[j * (max_bin - 1)
                                                    + j_value, k * (max_bin - 1) + k_value])
                e -= (fields_view[j * (max_bin - 1) + j_value])
        energies_view[i] = e
    return energies