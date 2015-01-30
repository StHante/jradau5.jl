# jradau5.jl

This implementation aims to empower every Julia user to use the
famous RADAU5 integrator from Hairer and Wanner natively in Julia.

The interface is supposed to be as easy as calling one of the solvers
from ODE.jl, which can be found here
https://github.com/JuliaLang/ODE.jl/

The code works at the moment for rather simple problems and implements
(I think) the same features as the ODE solvers in ODE.jl.
Further improvements will include using all the features of RADAU5
in Julia that the original FORTRAN77 code allows.

The original RADAU5 code include the lapack-routines can be found
on Hairers web page
http://www.unige.ch/~hairer/software.html
These files are only in the repo, so it can be compiled easily.

I appreciate every help concering licenses.
