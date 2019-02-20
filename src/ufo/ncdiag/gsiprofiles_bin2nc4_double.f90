PROGRAM gsiprofiles_bin2nc4

  USE netcdf

  USE ncd_kinds,ONLY: r_single, r_kind, i_kind

  IMPLICIT NONE 

  REAL,PARAMETER::     missing = -9.99e9
  INTEGER,PARAMETER:: imissing = -999999

  INTEGER nargs, iargc, n,i
  CHARACTER*256, ALLOCATABLE ::   arg(:)

  INTEGER(i_kind),PARAMETER :: max_name_length=56,max_vars=50

! commandline variables
  LOGICAL                              ::  debug 
  LOGICAL                              ::  append_suffix 

  CHARACTER*256 infn, outfn
  LOGICAL linfile, loutfile

  INTEGER,PARAMETER                    ::  inlun = 51
  INTEGER,PARAMETER                    ::  outlun= 52

  INTEGER strlen, iflag

  LOGICAL,DIMENSION(:),ALLOCATABLE     :: luse

! single variables used later for printing purposes
  CHARACTER(len=max_name_length), DIMENSION(max_vars) :: varnames

  INTEGER :: idate,nsig,nvars,naeros,nvarsphys,nsig_plus_one,nlocs

  REAL(r_single), ALLOCATABLE, DIMENSION(:) :: tsen,mixr,rh,prsltmp
  REAL(r_single), ALLOCATABLE, DIMENSION(:) :: prsitmp
  REAL(r_single), ALLOCATABLE, DIMENSION(:,:) :: aeros

  INTEGER, DIMENSION(2) :: start,count_nsig,count_nsig_plus_one

  INTEGER :: ncfileid,ncstatus,&
       &dimid_nsig,dimid_nsig_plus_one,dimid_nlocs
  
  INTEGER, DIMENSION(2) :: dimid_2d

  INTEGER :: ncid_tsen,ncid_mixr,ncid_rh,ncid_prsltmp,ncid_prsitmp
  INTEGER, ALLOCATABLE, DIMENSION(:) :: ncid_aeros

  nargs = iargc()
  IF( nargs.EQ.0 ) THEN
     CALL usage
  ELSE
     debug = .FALSE.
     append_suffix = .FALSE.

     ALLOCATE(arg(nargs))
     DO n=1,nargs
        CALL getarg(n,arg(n))
     ENDDO
     DO n=1,nargs
        IF (TRIM(arg(n)).EQ.'-debug'     ) debug=.TRUE.
        IF (TRIM(arg(n)).EQ.'-append_nc4') append_suffix=.TRUE.
     ENDDO
  ENDIF

  IF (debug) WRITE(*,*)'Debugging on - Verbose Printing'

! get infn from command line
  CALL getarg(nargs, infn)

  strlen = LEN(TRIM(infn))

  WRITE(*,*)'Input bin diag:  ',TRIM(infn)
  INQUIRE(file=TRIM(infn), exist=linfile)
  IF (.NOT. linfile) THEN
     WRITE(*,*)TRIM(infn) // ' does not exist - exiting'
     CALL abort
  ENDIF

  IF (.NOT. append_suffix) THEN
     outfn = infn(1:strlen-3) // 'nc4'  ! assumes GMAO diag filename format ending with .bin, and replaces it
  ELSE
     outfn = infn(1:strlen) // '.nc4'    ! if not GMAO format, use append_suffix = .true. in namelist 
!   to simply append infile with .nc4 suffix
  ENDIF

  WRITE(*,*)'Output NC4 diag: ',TRIM(outfn)
  INQUIRE(file=TRIM(outfn), exist=loutfile)
  IF (loutfile) WRITE(*,*)'WARNING: ' // TRIM(outfn) // ' exists - overwriting'

  iflag = 0

  OPEN(inlun,file=infn,form='unformatted',convert='big_endian')
  ncstatus    = nf90_create(TRIM(outfn),NF90_CLOBBER,ncid=ncfileid)

  varnames=''
  CALL read_profiles_header( inlun,idate,nsig,nvars,naeros,varnames,&
       &iflag,debug)

  nvarsphys=nvars-naeros
  nsig_plus_one=nsig+1

  ncstatus    = nf90_def_dim(ncfileid,'nsig',nsig,dimid_nsig)
  ncstatus    = nf90_def_dim(ncfileid,'nsig_plus_one',nsig_plus_one,&
       &dimid_nsig_plus_one)
  ncstatus    = nf90_def_dim(ncfileid,'nlocs',NF90_UNLIMITED, dimid_nlocs)

  ALLOCATE(ncid_aeros(naeros))

  dimid_2d=(/dimid_nsig,dimid_nlocs/)

  ncstatus    = nf90_def_var(ncfileid,"air_temperature",nf90_double,dimid_2d,&
       &ncid_tsen)
  ncstatus    = nf90_def_var(ncfileid,"humidity_mixing_ratio",nf90_double,dimid_2d,&
       &ncid_mixr)

  ncstatus    = nf90_def_var(ncfileid,"relative_humidity",nf90_double,dimid_2d,&
       &ncid_rh)

  ncstatus    = nf90_def_var(ncfileid,"air_pressure",nf90_double,dimid_2d,&
       &ncid_prsltmp)

  DO i=1,naeros
     ncstatus    = nf90_def_var(ncfileid,TRIM(varnames(nvarsphys+i)),&
          &nf90_double,dimid_2d,ncid_aeros(i))
  ENDDO

  dimid_2d=(/dimid_nsig_plus_one,dimid_nlocs/)

  ncstatus    = nf90_def_var(ncfileid,"air_pressure_levels",nf90_double,dimid_2d,&
       &ncid_prsitmp)
  
  ncstatus    = nf90_put_att(ncfileid, NF90_GLOBAL, 'date_time', idate)

  ncstatus    = nf90_enddef(ncfileid)

!  PRINT *,trim(nf90_strerror(ncstatus))

  nvarsphys=nvars-naeros

  ALLOCATE(tsen(nsig),mixr(nsig),rh(nsig),prsltmp(nsig),prsitmp(nsig+1),&
       &aeros(nsig,naeros))

  n=0

  iflag=0

  start=(/1,1/)
  count_nsig=(/nsig,1/)
  count_nsig_plus_one=(/nsig_plus_one,1/)

  DO WHILE (iflag == 0) 

     CALL read_profiles(inlun,nsig,nvarsphys,naeros,&
       &tsen,mixr,rh,prsltmp,prsitmp,aeros,iflag,debug)

     tsen(1:nsig)=tsen(nsig:1:-1)
     mixr(1:nsig)=mixr(nsig:1:-1)*1000_r_single
     rh(1:nsig)=rh(nsig:1:-1)
     prsltmp(1:nsig)=prsltmp(nsig:1:-1) * 10_r_single
     prsitmp(1:nsig+1)=prsitmp(nsig+1:1:-1) *10_r_single
     aeros(1:nsig,:)=aeros(nsig:1:-1,:)

     IF (iflag /= 0) EXIT

     start(2)=n+1

     ncstatus    = nf90_put_var(ncfileid,ncid_tsen,tsen,start=start,&
          &count=count_nsig)
     ncstatus    = nf90_put_var(ncfileid,ncid_mixr,mixr,start=start,&
          &count=count_nsig)
     ncstatus    = nf90_put_var(ncfileid,ncid_rh,rh,start=start,&
          &count=count_nsig)
     ncstatus    = nf90_put_var(ncfileid,ncid_prsltmp,prsltmp,&
          &start=start,count=count_nsig)

     ncstatus    = nf90_put_var(ncfileid,ncid_prsitmp,prsitmp,&
          &start=start,count=count_nsig_plus_one)

     DO i=1,naeros
        ncstatus    = nf90_put_var(ncfileid,ncid_aeros(i),aeros(:,i),&
             &start=start,count=count_nsig)     
     ENDDO

     n=n+1

  ENDDO

  PRINT *,'There are ',n,' observations'

  ncstatus    = nf90_close(ncfileid)

  DEALLOCATE(ncid_aeros,tsen,mixr,rh,prsltmp,prsitmp,aeros)

CONTAINS

  SUBROUTINE usage

    WRITE(6,100)
100 FORMAT( "Usage:  ",/,/ &
         "  convert_aod_diag.x <options> <filename>",/,/ &
         "where options:",/ &
         "  -debug              :  Set debug verbosity",/ &
         "  -append_txt         :  Append .txt suffix, instead of replace last three",/ &
         "                             characters (default: replaced)",/ &
         "                             Note:  The GMAO diag files end with .bin or .nc4,",/ &
         "                               which is where fixed 3-char truncation originates",/,/,/ &
         "  Example:",/ &
         "     convert_aod_diag.x nc_4emily.diag_hirs4_n19_ges.20161202_00z.bin",/ &
         "  Output file:",/ &
         "     nc_4emily.diag_hirs4_n19_ges.20161202_00z.nc4",/ &
         )
    STOP

  END SUBROUTINE usage


  SUBROUTINE read_profiles_header(ftin,idate,nsig,nvars,naeros,varnames,iflag,lverbose)
!                .      .    .                                       .
! Declare passed arguments
    INTEGER,INTENT(in)             :: ftin
    INTEGER,INTENT(out) :: idate,nsig,nvars,naeros
    CHARACTER(len=max_name_length), DIMENSION(max_vars) :: &
         &varnames
    INTEGER,INTENT(out)            :: iflag
    LOGICAL,OPTIONAL,INTENT(in)            :: lverbose    

    LOGICAL loutall

    loutall=.TRUE.
    IF(PRESENT(lverbose)) loutall=lverbose

! Read header (fixed_part).

    READ(ftin,IOSTAT=iflag)  nsig,nvars,naeros,idate
    READ(ftin,IOSTAT=iflag)  varnames(1:nvars)

  END SUBROUTINE read_profiles_header

  SUBROUTINE read_profiles(ftin,nsig,nvarsphys,naeros,&
       &tsen,mixr,rh,prsltmp,prsitmp,aeros,iflag,lverbose)
!                .      .    .                                       .
! Declare passed arguments
    INTEGER,INTENT(in)             :: ftin
    INTEGER,INTENT(in) :: nsig,nvarsphys,naeros
    REAL(r_single), DIMENSION(nsig) :: tsen,mixr,rh,prsltmp
    REAL(r_single), DIMENSION(nsig+1) :: prsitmp
    REAL(r_single), DIMENSION(nsig,naeros) :: aeros
    INTEGER,INTENT(out)            :: iflag
    LOGICAL,OPTIONAL,INTENT(in)            :: lverbose    

    LOGICAL loutall

    loutall=.TRUE.
    IF(PRESENT(lverbose)) loutall=lverbose

    READ(ftin,IOSTAT=iflag) tsen,mixr,rh,prsltmp,prsitmp
    READ(ftin,IOSTAT=iflag) aeros

  END SUBROUTINE read_profiles

END PROGRAM gsiprofiles_bin2nc4