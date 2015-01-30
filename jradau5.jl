module jradau5

function r_fcn(p_N   ::Ptr{Int64}, 
               p_X   ::Ptr{Float64},
               p_Y   ::Ptr{Float64},
               p_F   ::Ptr{Float64},
               p_RPAR::Ptr{Float64},
               p_IPAR::Ptr{Int64},
               j_out ::Ptr{Void}, # FIXME: needed?
               j_fcn ::Ptr{Void})
   # Tell Julia how to use the pointers as arrays
   n_arr = pointer_to_array(p_N, 1)
   x_arr = pointer_to_array(p_X, 1)
   y     = pointer_to_array(p_Y, n_arr[1])
   f     = pointer_to_array(p_F, n_arr[1])
   #FIXME: RPAR and IPAR unsupported
   # Tell Julia j_fcn is actually a Julia funtion
   fcn   = unsafe_pointer_to_objref(j_fcn)::Function
   
   # Actual function call
   f[:] = fcn(x_arr[1], y)
   
   ## Other method to do the function call
   #f = fcn(x_arr[1], y)
   #
   #for i=1:n
   #   unsafe_store!(p_F, f[i], i)
   #end
   #
   ##DEBUG
   #@printf("x = %f,\t y = %f\t, f = %f\n", x_arr[1], y[1], f[1])
   
   # Return anything since this is called as a Fortran subroutine
   return convert(Int64, 0)
end

function r_solout(p_NR     ::Ptr{Int64},
                  p_XOLD   ::Ptr{Float64},
                  p_X      ::Ptr{Float64},
                  p_Y      ::Ptr{Float64},
                  p_CONT   ::Ptr{Float64},
                  p_LRC    ::Ptr{Float64},
                  p_N      ::Ptr{Int64},
                  p_RPAR   ::Ptr{Float64},
                  p_IPAR   ::Ptr{Int64},
                  j_out    ::Ptr{Void},
                  j_solout ::Ptr{Void})
   # Tell Julia how to use the pointers as arrays
   nr_arr   = pointer_to_array(p_NR,   1)
   xold_arr = pointer_to_array(p_XOLD, 1)
   x_arr    = pointer_to_array(p_X,    1)
   n_arr    = pointer_to_array(p_N,    1)
   y        = pointer_to_array(p_Y,    n_arr[1])
   #FIXME: Continuous output unsupported
   #FIXME: RPAR and IPAR unsupported
   # Tell Julia that j_solout and j_out are actually a Julia objects 
   solout   = unsafe_pointer_to_objref(j_solout)
   out      = unsafe_pointer_to_objref(j_out)
   
   # Update out Variable
   tout, yout = out
   push!(tout, x_arr[1])
   push!(yout, deepcopy(y))
   
   if solout == 0
   else
      solout() # FIXME
   end
   
   # DEBUG
   @printf("nr=%d\t x = %f,\t y[1] = %f\n", nr_arr[1], x_arr[1], y[1])
   
   return convert(Int64, 0) # IRTRN
end

# FIXME
function solout_dummy()
   @printf("soloutdummy\n")
end
# EMXIF

function radau5(f::Function, tspan::Array{Int64,1}, y0::Array{Float64,1};
         rtol     ::Float64 = 1e-6,  # Scalar relative tolerance
         atol     ::Float64 = 1e-6,  # Scalar absolute tolerance
         h0       ::Float64 = 0.0,   # Size of first step (0.0 defaults to 1e-6)
         maxstp   ::Int64   = 0,     # Maximum number of allowed steps (0 defaults to 100000)
         maxnewtit::Int64   = 0,     # Maximum number of newton iterations for the solution of the implicit system in each step (0 defaults to 7)
         uround   ::Float64 = 0.0,   # Rounding unit (0.0 defaults to 1e-16)
         safety   ::Float64 = 0.0,   # Safety factor in step size prediction (0.0 defaults to 0.9)
         )
   # Make a C function of r_fcn, which wraps the input value f
   const c_fcn = cfunction(r_fcn, Int64,
                                   (Ptr{Int64},    # N
                                    Ptr{Float64},  # X
                                    Ptr{Float64},  # Y
                                    Ptr{Float64},  # F
                                    Ptr{Float64},  # RPAR
                                    Ptr{Int64},    # IPAR
                                    Ptr{Void},     # j_out
                                    Ptr{Void}))    # j_fcn
   # Make a C function of r_solout, which controls the output
   # and FIXME the user-defined output function
   const c_solout = cfunction(r_solout, Int64,
                 (Ptr{Int64},    # NR
                  Ptr{Float64},  # XOLD
                  Ptr{Float64},  # X
                  Ptr{Float64},  # Y
                  Ptr{Float64},  # CONT
                  Ptr{Float64},  # LRC
                  Ptr{Int64},    # N
                  Ptr{Float64},  # RPAR
                  Ptr{Int64},    # IPAR
                  Ptr{Void},     # j_out
                  Ptr{Void}))    # j_solout
   
   # Make a deep copy of y0, as RADAU5 will alter the variable
   y = convert(Array{Float64,1},deepcopy(y0))
   # Get dimension of the differential equation
   const n = length(y0)
   
   # Calulate the size for the work and iwork array and allocate them
   const lwork  = 4*n*n+12*n+20
   work   = zeros(Float64, lwork)
   const liwork = 3*n + 20
   iwork  = zeros(Int64, liwork)
   
   # Settings
   iwork[2] = maxstp
   iwork[3] = maxnewtit
   work[1] = uround
   work[2] = safety
   
   # Initialize output
   tout = Array(Float64, 0)
   yout = Array(Array{Float64,1},0)

   out = (tout, yout)
   
   # Call RADAU5
   idid = ccall((:radau5wrapfor, "./jradau5.so"), Int64,
      (Ptr{Int64},   # N
       Ptr{Void},    # FCN
       Ptr{Float64}, # X
       Ptr{Float64}, # Y
       Ptr{Float64}, # XEND
       Ptr{Float64}, # H
       Ptr{Float64}, # RTOL
       Ptr{Float64}, # ATOL
       Ptr{Int64},   # ITOL
       Ptr{Void},    # JAC
       Ptr{Int64},   # IJAC
       Ptr{Int64},   # MLJAC
       Ptr{Int64},   # MUJAC
       Ptr{Void},    # MAS
       Ptr{Int64},   # IMAS
       Ptr{Int64},   # MLMAS
       Ptr{Int64},   # MUMAS
       Ptr{Void},    # SOLOUT
       Ptr{Int64},   # IOUT
       Ptr{Float64}, # WORK
       Ptr{Int64},   # LWORK
       Ptr{Int64},   # IWORK
       Ptr{Int64},   # LIWORK
       Ptr{Float64}, # RPAR
       Ptr{Int64},   # IPAR
       Any,          # j_out
       Any,          # j_fcn
       Any           # j_solout
      ),
      &n,         # N
      c_fcn,      # FCN
      &tspan[1],  # X
      y,          # Y
      &tspan[end],# XEND
      &h0,        # H
      &rtol,      # RTOL    FIXME: Support vector-valued tolerances
      &atpö,      # ATOL    FIXME: - "" -
      &0,         # ITOL    FIXME: - "" -
      0,          # JAC     FIXME: Support analytic jacobian
      &0,         # IJAC    FIXME: - "" -
      &n,         # MLJAC   FIXME: - "" -
      &n,         # MUJAC   FIXME: - "" -
      0,          # MAS     FIXME: Support non-identity mass matrix
      &0,         # IMAS    FIXME: - "" -
      &0,         # MLMAS   FIXME: - "" -
      &0,         # MUMAS   FIXME: - "" -
      c_solout,   # SOLOUT
      &1,         # IOUT
      work,       # WORK    FIXME!!
      &lwork,     # LWORK   FIXME!!
      iwork,      # IWORK   FIXME!!
      &liwork,    # LIWORK  FIXME!!
      &0,         # RPAR    FIXME!!
      &0,         # IPAR    FIXME!!
      out,        # j_out
      f,          # j_fcn
      solout_dummy# j_soloutFIXME!!
      )
   
   return out[1], out[2]
end


end
