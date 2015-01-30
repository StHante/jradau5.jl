function radau5wrapfor( N,  c_FCN,  X,  Y,  XEND,  H,    &
                        RTOL,  ATOL,  ITOL,              &
                        c_JAC,  IJAC,  MLJAC,  MUJAC,    &
                        c_MAS,  IMAS,  MLMAS,  MUMAS,    &
                        c_SOLOUT,  IOUT,                 &
                        WORK,  LWORK,  IWORK,  LIWORK,   &
                        RPAR,  IPAR,                     &
                        j_out, j_fcn, j_solout) result(IDID) bind(c, name="radau5wrapfor")
   use, intrinsic          :: iso_c_binding
   implicit none
   ! Define input variables !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   integer,    intent(in)     :: N
   type(c_funptr),      value :: c_FCN
   real,       intent(in)     :: X, Y(N), XEND, H
   real,       intent(in)     :: RTOL, ATOL !FIXME: Only ITOL=0 supported
   integer,    intent(in)     :: ITOL
   type(c_funptr),      value :: c_JAC !FIXME: Only IJAC=0 supported
   integer,    intent(in)     :: IJAC, MLJAC, MUJAC
   type(c_funptr),      value :: c_MAS !FIXME: Only IMAS=0 supported
   integer,    intent(in)     :: IMAS, MLMAS, MUMAS
   type(c_funptr),      value :: c_SOLOUT
   integer,    intent(in)     :: IOUT
   integer,    intent(in)     :: LWORK
   real,       intent(in)     :: WORK(LWORK)
   integer,    intent(in)     :: LIWORK
   integer,    intent(in)     :: IWORK(LIWORK)
   real,       intent(inout)  :: RPAR(*) !FIXME: Use : instead of * ? !FIXME: Not supported yet
   integer,    intent(inout)  :: IPAR(*) !FIXME: Use : instead of * ? !FIXME: Not supported yet
   type(c_ptr),         value :: j_out
   type(c_ptr),         value :: j_fcn
   type(c_ptr),         value :: j_solout
   ! Define result variable !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   integer                    :: IDID
   ! Define abstract interfaces !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   abstract interface
      subroutine fcn_iface(N, X, Y, F, RPAR, IPAR, j_out, j_fcn)
         import                  :: c_ptr
         ! Define subroutine arguments
         integer, intent(in)     :: N
         real,    intent(in)     :: X, Y(N)
         real,    intent(inout)  :: RPAR(*) !FIXME: : instead of * ?
         integer, intent(inout)  :: IPAR(*) !FIXME: : instead of * ?
         real,    intent(  out)  :: F(N)
         type(c_ptr),      value :: j_out
         type(c_ptr),      value :: j_fcn
      end subroutine fcn_iface
      
      function solout_iface(NR,  XOLD,  X,  Y,  CONT,  LRC,  N, &
                            RPAR,  IPAR,  j_out,  j_solout) result(IRTRN)
         import                  :: c_ptr
         ! Define function arguments
         integer, intent(in)     :: NR
         real,    intent(in)     :: XOLD, X
         integer, intent(in)     :: N
         real,    intent(in)     :: Y(N)
         integer, intent(in)     :: LRC
         real,    intent(in)     :: CONT(LRC)
         real,    intent(inout)  :: RPAR(*)
         integer, intent(inout)  :: IPAR(*)
         type(c_ptr),      value :: j_out
         type(c_ptr),      value :: j_solout
         ! Define return value
         integer                 :: IRTRN
      end function solout_iface
   end interface
   ! Define internal variables !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   procedure(fcn_iface),      pointer  :: f_FCN
   procedure(solout_iface),   pointer  :: f_SOLOUT
   ! Make fortran procedure pointers from the c function pointers !!!!!!
   call c_f_procpointer(c_FCN, f_FCN)
   call c_f_procpointer(c_SOLOUT, f_SOLOUT)
   ! Call radau5 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   call RADAU5(N,  fcn,                      &
               X,  Y,  XEND,  H,             &
               RTOL,  ATOL,  ITOL,           &
               jac,  IJAC,  MLJAC,  MUJAC,   & 
               mas,  IMAS,  MLMAS,  MUMAS,   & 
               solout,  IOUT,                & 
               WORK,  LWORK,  IWORK,  LIWORK,&
               RPAR,  IPAR,  IDID)



! Define contained subroutines !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
contains
   ! Right hand side !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   subroutine fcn(fcn_N, fcn_X, fcn_Y, fcn_F, fcn_RPAR, fcn_IPAR)
      implicit none
      ! Define subroutine arguments
      integer, intent(in)     :: fcn_N
      real,    intent(in)     :: fcn_X, fcn_Y(fcn_N)
      real,    intent(inout)  :: fcn_RPAR(*) !FIXME: : instead of * ? !FIXME: willingly pass wrong real size?
      integer, intent(inout)  :: fcn_IPAR(*) !FIXME: : instead of * ? !FIXME: willingly pass wrong real size?
      real,    intent(  out)  :: fcn_F(fcn_N)
      ! Actual function call
      call f_FCN( fcn_N,      &
                  fcn_X,      &
                  fcn_Y,      &
                  fcn_F,      &
                  fcn_RPAR,   &
                  fcn_IPAR,   &
                  j_out,      &
                  j_fcn)
   end subroutine fcn
   
   subroutine jac()
      !FIXME: Implement
   end subroutine jac
   
   subroutine mas()
      !FIXME: Implement
   end subroutine mas
   
   ! Output function !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   subroutine solout(solout_NR,  solout_XOLD,  solout_X,  solout_Y, &
                     solout_CONT,  solout_LRC,  solout_N,           &
                     solout_RPAR,  solout_IPAR,  solout_IRTRN)
      implicit none
      ! Define subroutine arguments
      integer, intent(in)     :: solout_NR
      real,    intent(in)     :: solout_XOLD, solout_X
      integer, intent(in)     :: solout_N
      real,    intent(in)     :: solout_Y(solout_N)
      integer, intent(in)     :: solout_LRC
      real,    intent(in)     :: solout_CONT(solout_LRC)
      real,    intent(inout)  :: solout_RPAR(*)
      integer, intent(inout)  :: solout_IPAR(*)
      integer, intent(  out)  :: solout_IRTRN
      ! Actual function call
      solout_IRTRN = f_SOLOUT(solout_NR,     &
                              solout_XOLD,   &
                              solout_X,      &
                              solout_Y,      &
                              solout_CONT,   &
                              solout_LRC,    &
                              solout_N,      &
                              solout_RPAR,   &
                              solout_IPAR,   &
                              j_out,         &
                              j_solout)
   end subroutine solout
end function radau5wrapfor

