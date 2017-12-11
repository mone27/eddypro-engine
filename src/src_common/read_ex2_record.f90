!***************************************************************************
! read_ex_record.f90
! ------------------
! Copyright (C) 2011-2015, LI-COR Biosciences
!
! This file is part of EddyPro (TM).
!
! EddyPro (TM) is free software: you can redistribute it and/or modify
! it under the terms of the GNU General Public License as published by
! the Free Software Foundation, either version 3 of the License, or
! (at your option) any later version.
!
! EddyPro (TM) is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
! GNU General Public License for more details.
!
! You should have received a copy of the GNU General Public License
! along with EddyPro (TM).  If not, see <http://www.gnu.org/licenses/>.
!
!***************************************************************************
!
! \brief       Read one record of essentials file. Based on the requested
!              record number, either reads following record (rec_num < 0)
!              or open the file and look for the actual rec_num
! \author      Gerardo Fratini
! \note
! \sa
! \bug
! \deprecated
! \test
! \todo
!***************************************************************************
subroutine ReadEx2Record(FilePath, unt, rec_num, lEx2, ValidRecord, EndOfFileReached)
    use m_common_global_var
    !> In/out variables
    character(*), intent(in) :: FilePath
    integer, intent(in) :: rec_num
    logical, intent(out) :: ValidRecord
    logical, intent(out) :: EndOfFileReached
    type (ExType), intent(out) :: lEx2
    integer, intent(inout) :: unt
    !> Local variables
    integer :: open_status
    integer :: read_status
    integer :: i
    integer :: var
    integer :: ix
    character(16000) :: dataline
    include 'interfaces_1.inc'

    ! integer, external :: strCharIndex

    !> If rec_num > 0,open file and moves to the requested record
    if (rec_num > 0) then
        open(udf, file = trim(adjustl(FilePath)), status = 'old', iostat = open_status)
        if (open_status /= 0) call ExceptionHandler(60)
        unt = udf
        !> Skip header and all records until the requested one
        do i = 1, rec_num
            read(unt, *)
        end do
    end if

    !> Read data line
    ValidRecord = .true.
    EndOfFileReached = .false.
    read(unt, '(a)', iostat = read_status) dataline

    ! !> Controls on what was read
    ! if (read_status > 0 .or. index(dataline, 'not_enough_data') /= 0) then
    !     ValidRecord = .false.
    !     if (rec_num > 0) close(unt)
    !     return
    ! end if

    if (read_status < 0) then
        EndOfFileReached = .true.
        if (rec_num > 0) close(unt)
        return
    end if

    !> Replace error code with -9999
    dataline = replace2(dataline, trim(EddyProProj%err_label), '-9999')

    !> Read timestamp and eliminate if from dataline
    lEx2%timestamp = dataline(1:14)
    lEx2%date = lEx2%timestamp(1:4) // '-' // lEx2%timestamp(5:6) // '-' // lEx2%timestamp(7:8) 
    lEx2%time = lEx2%timestamp(9:10) // ':' // lEx2%timestamp(11:12)  
    dataline = dataline(16: len_trim(dataline))

    !> Extract some data
    read(dataline, *, iostat = read_status) lEx2%RP, lEx2%daytime_int, lEx2%nr_theor, &
        lEx2%nr_files, lEx2%nr_after_custom_flags, lEx2%nr_after_wdf, &
        lEx2%nr(u), lEx2%nr(ts:gas4), lEx2%nr_w(u), lEx2%nr_w(ts:gas4)
    ix = strCharIndex(dataline, ',', 18)
    dataline = dataline(ix+1: len_trim(dataline))

    !> Skip final fluxes (they are recalculated in FCC)
    ix = strCharIndex(dataline, ',', 7)
    dataline = dataline(ix+1: len_trim(dataline))

    !> Extract random uncertainties
    read(dataline, *, iostat = read_status) &
        lEx2%rand_uncer(u), lEx2%rand_uncer(ts), &
        lEx2%rand_uncer_LE, lEx2%rand_uncer(co2:gas4), &
        lEx2%Stor%H, lEx2%Stor%LE, lEx2%Stor%of(co2:gas4)
    ix = strCharIndex(dataline, ',', 13)
    dataline = dataline(ix+1: len_trim(dataline))
        
    !> Skip vertical advections (they are recalculated in FCC)
    ix = strCharIndex(dataline, ',', 4)
    dataline = dataline(ix+1: len_trim(dataline))

    !> Extract rotated and unrotated wind components
    read(dataline, *, iostat = read_status) &        
        lEx2%unrot_u, lEx2%unrot_v, lEx2%unrot_w, lEx2%rot_u, lEx2%rot_v, lEx2%rot_w, &
        lEx2%WS, lEx2%MWS, lEx2%WD, lEx2%ustar, lEx2%TKE, lEx2%L, lEx2%zL, lEx2%Bowen, lEx2%Tstar, &
        lEx2%Ts, lEx2%Ta, lEx2%Pa, lEx2%RH, lEx2%Va, lEx2%RHO%a, lEx2%RhoCp, &
        lEx2%RHO%w, lEx2%e, lEx2%es, lEx2%Q, lEx2%VPD, lEx2%Tdew, &
        lEx2%Pd, lEx2%RHO%d, lEx2%Vd, lEx2%lambda, lEx2%sigma, &
        lEx2%measure_type_int(co2), lEx2%d(co2), lEx2%r(co2), lEx2%chi(co2), &
        lEx2%measure_type_int(h2o), lEx2%d(h2o), lEx2%r(h2o), lEx2%chi(h2o), &
        lEx2%measure_type_int(ch4), lEx2%d(ch4), lEx2%r(ch4), lEx2%chi(ch4), &
        lEx2%measure_type_int(gas4), lEx2%d(gas4), lEx2%r(gas4), lEx2%chi(gas4), &
        lEx2%act_tlag(co2), lEx2%used_tlag(co2), lEx2%nom_tlag(co2), lEx2%min_tlag(co2), lEx2%max_tlag(co2), &
        lEx2%act_tlag(h2o), lEx2%used_tlag(h2o), lEx2%nom_tlag(h2o), lEx2%min_tlag(h2o), lEx2%max_tlag(h2o),&
        lEx2%act_tlag(ch4), lEx2%used_tlag(ch4), lEx2%nom_tlag(ch4), lEx2%min_tlag(ch4), lEx2%max_tlag(ch4),&
        lEx2%act_tlag(gas4), lEx2%used_tlag(gas4), lEx2%nom_tlag(gas4), lEx2%min_tlag(gas4), lEx2%max_tlag(gas4), &
        lEx2%stats%mean(u:gas4), lEx2%stats%median(u:gas4), lEx2%stats%Q1(u:gas4), lEx2%stats%Q3(u:gas4), &
        (lEx2%stats%Cov(var, var), var=u, gas4), lEx2%stats%Skw(u:gas4), lEx2%stats%Kur(u:gas4), &
        lEx2%stats%Cov(w, u), lEx2%stats%Cov(w, ts:gas4), lEx2%stats%Cov(co2, h2o:gas4), &
        lEx2%stats%Cov(h2o, ch4:gas4), lEx2%stats%Cov(ch4, gas4)
    ix = strCharIndex(dataline, ',', 137)
    dataline = dataline(ix+1: len_trim(dataline))

    !> Skip footprint (it's recalculated in FCC)
    ix = strCharIndex(dataline, ',', 7)
    dataline = dataline(ix+1: len_trim(dataline))

    !> Read out Flux0 data
    read(dataline, *, iostat = read_status) lEx2%Flux0%L, lEx2%Flux0%zL, &
        lEx2%Flux0%Tau, lEx2%Flux0%H, lEx2%Flux0%LE, lEx2%Flux0%co2, lEx2%Flux0%h2o, lEx2%Flux0%ch4, lEx2%Flux0%gas4
    ix = strCharIndex(dataline, ',', 7)
    dataline = dataline(ix+1: len_trim(dataline))

    !> skip Flux1 and Flux2 (they are recalculated in FCC)
    ix = strCharIndex(dataline, ',', 16)
    dataline = dataline(ix+1: len_trim(dataline))

    !> Read out some data
    read(dataline, *, iostat = read_status) &
        lEx2%Tcell, lEx2%Pcell, lEx2%Vcell(co2:gas4), &
        lEx2%Flux0%E_co2, lEx2%Flux0%E_ch4, lEx2%Flux0%E_gas4, &
        lEx2%Flux0%Hi_co2, lEx2%Flux0%Hi_h2o, lEx2%Flux0%Hi_ch4, lEx2%Flux0%Hi_gas4, &
        lEx2%Burba%h_bot, lEx2%Burba%h_top, lEx2%Burba%h_spar, &
        lEx2%Mul7700%A, lEx2%Mul7700%B, lEx2%Mul7700%C
    ix = strCharIndex(dataline, ',', 19)
    dataline = dataline(ix+1: len_trim(dataline))

    !> Skip SCFs (they are recalculated in FCC)
    ix = strCharIndex(dataline, ',', 7)
    dataline = dataline(ix+1: len_trim(dataline))

    !> Read out degraded covariances
    read(dataline, *, iostat = read_status) lEx2%degT%cov, lEx2%degT%dcov(1:9)
    ix = strCharIndex(dataline, ',', 10)
    dataline = dataline(ix+1: len_trim(dataline))

    !> Copy M_CUSTOM_FLAGS thru VM97_NSW_RNS
    ix = strCharIndex(dataline, ',', 75)
    icosChunks%s(1) = dataline(1: ix-1)
    dataline = dataline(ix+1: len_trim(dataline))

    !> Read out VM flags and Foken QC details
    read(dataline, *, iostat = read_status) &
        lEx2%vm_flags(1:12), lEx2%st_w_u, lEx2%st_w_ts, lEx2%st_w_co2, lEx2%st_w_h2o, &
        lEx2%st_w_ch4, lEx2%st_w_gas4, lEx2%dt_u, lEx2%dt_w, lEx2%dt_ts
    ix = strCharIndex(dataline, ',', 21)
    dataline = dataline(ix+1: len_trim(dataline))

    !> Copy FK04_ST_FLAG_W_U thru ...
    ix = strCharIndex(dataline, ',', 24)
    icosChunks%s(2) = dataline(1: ix-1)
    dataline = dataline(ix+1: len_trim(dataline))

    !> Read licor IRGA flags
    read(dataline, *, iostat = read_status) lEx2%licor_flags(1:29)
    ix = strCharIndex(dataline, ',', 29)
    dataline = dataline(ix+1: len_trim(dataline))

    !> Read AGC/RSSI
    read(dataline, *, iostat = read_status) lEx2%agc72,lEx2%agc75,lEx2%rssi77
    ix = strCharIndex(dataline, ',', 3)
    dataline = dataline(ix+1: len_trim(dataline))

    !> Copy WBOOST_APPLIED thru AXES_ROTATION_METHOD
    ix = strCharIndex(dataline, ',', 3)
    icosChunks%s(3) = dataline(1: ix-1)
    dataline = dataline(ix+1: len_trim(dataline))

    !> Read rotation angles and detrending method/time constant
    read(dataline, *, iostat = read_status) &
        lEx2%yaw, lEx2%pitch, lEx2%roll, lEx2%det_meth_int, lEx2%det_timec
    ix = strCharIndex(dataline, ',', 5)
    dataline = dataline(ix+1: len_trim(dataline))

    !> Copy TIMELAG_DETECTION_METHOD thru FOOTPRINT_MODEL
    ix = strCharIndex(dataline, ',', 5)
    icosChunks%s(4) = dataline(1: ix-1)
    dataline = dataline(ix+1: len_trim(dataline))

    !> Read out metadata
    read(dataline, *, iostat = read_status) &
        lEx2%logger_swver%major,lEx2%logger_swver%minor,lEx2%logger_swver%revision, &
        lEx2%lat, lEx2%lon, lEx2%alt, &
        lEx2%canopy_height, lEx2%disp_height, lEx2%rough_length, &
        lEx2%file_length, lEx2%ac_freq, lEx2%avrg_length, &
        lEx2%instr(sonic)%firm, lEx2%instr(sonic)%model, lEx2%instr(sonic)%height, &
        lEx2%instr(sonic)%wformat, lEx2%instr(sonic)%wref, lEx2%instr(sonic)%north_offset, &
        lEx2%instr(sonic)%hpath_length, lEx2%instr(sonic)%vpath_length, lEx2%instr(sonic)%tau, &
        lEx2%instr(ico2)%firm, lEx2%instr(ico2)%model, lEx2%instr(ico2)%nsep, lEx2%instr(ico2)%esep, &
        lEx2%instr(ico2)%vsep, lEx2%instr(ico2)%tube_l, lEx2%instr(ico2)%tube_d, &
        lEx2%instr(ico2)%tube_f, lEx2%instr(ico2)%kw, lEx2%instr(ico2)%ko, &
        lEx2%instr(ico2)%hpath_length, lEx2%instr(ico2)%vpath_length, lEx2%instr(ico2)%tau, &
        lEx2%instr(ih2o)%firm, lEx2%instr(ih2o)%model, lEx2%instr(ih2o)%nsep, lEx2%instr(ih2o)%esep, &
        lEx2%instr(ih2o)%vsep, lEx2%instr(ih2o)%tube_l, lEx2%instr(ih2o)%tube_d, &
        lEx2%instr(ih2o)%tube_f, lEx2%instr(ih2o)%kw, lEx2%instr(ih2o)%ko, &
        lEx2%instr(ih2o)%hpath_length, lEx2%instr(ih2o)%vpath_length, lEx2%instr(ih2o)%tau, &
        lEx2%instr(ich4)%firm, lEx2%instr(ich4)%model, lEx2%instr(ich4)%nsep, lEx2%instr(ich4)%esep, &
        lEx2%instr(ich4)%vsep, lEx2%instr(ich4)%tube_l, lEx2%instr(ich4)%tube_d, &
        lEx2%instr(ich4)%tube_f, lEx2%instr(ich4)%kw, lEx2%instr(ich4)%ko, &
        lEx2%instr(ich4)%hpath_length, lEx2%instr(ich4)%vpath_length, lEx2%instr(ich4)%tau, &
        lEx2%instr(igas4)%firm, lEx2%instr(igas4)%model, lEx2%instr(igas4)%nsep, lEx2%instr(igas4)%esep, &
        lEx2%instr(igas4)%vsep, lEx2%instr(igas4)%tube_l, lEx2%instr(igas4)%tube_d, &
        lEx2%instr(igas4)%tube_f, lEx2%instr(igas4)%kw, lEx2%instr(igas4)%ko, &
        lEx2%instr(igas4)%hpath_length, lEx2%instr(igas4)%vpath_length, lEx2%instr(igas4)%tau
    ix = strCharIndex(dataline, ',', 73)
    dataline = dataline(ix+1: len_trim(dataline))

    !> Put remaining into last chunk
    icosChunks%s(5) = dataline(1: len_trim(dataline))

    ! !> Complete essentials information based on retrieved ones
    call CompleteEssentials2(lEx2)

    !> Close file only if it wasn't open on entrance
    if (rec_num > 0) close(unt)
end subroutine ReadEx2Record

!***************************************************************************
!
! \brief       Complete essentials information, based on those retrieved \n
!              from the file be useful to other programs
! \author      Gerardo Fratini
! \note
! \sa
! \bug
! \deprecated
! \test
! \todo
!***************************************************************************
subroutine CompleteEssentials2(lEx2)
    use m_common_global_var
    implicit none
    !> in/out variables
    type(ExType), intent(inout) :: lEx2
    !> local variables
    integer :: gas
    integer :: var

    lEx2%var_present = .false.
    if (lEx2%WS /= error) lEx2%var_present(u:w) = .true.
    if (lEx2%Ts /= error) lEx2%var_present(ts)  = .true.
    if (lEx2%Flux0%co2  /= error) lEx2%var_present(co2) = .true.
    if (lEx2%Flux0%h2o  /= error) lEx2%var_present(h2o) = .true.
    if (lEx2%Flux0%ch4  /= error) lEx2%var_present(ch4) = .true.
    if (lEx2%Flux0%gas4 /= error) lEx2%var_present(gas4) = .true.

    lEx2%instr(ico2:igas4)%category = 'irga'
    lEx2%instr(sonic)%category = 'sonic'
    !> Determine whether gas analysers are open or closed path
    do gas = ico2, igas4
        select case (lEx2%instr(gas)%model(1:len_trim(lEx2%instr(gas)%model) - 2))
            case ('li7700', 'li7500', 'li7500a', 'li7500rs', 'generic_open_path', &
                'open_path_krypton', 'open_path_lyman')
                lEx2%instr(gas)%path_type = 'open'
            case default
                lEx2%instr(gas)%path_type = 'closed'
        end select
        if (lEx2%instr(gas)%nsep /= error .and. lEx2%instr(gas)%esep /= error) then
            lEx2%instr(gas)%hsep = dsqrt(lEx2%instr(gas)%nsep**2 + lEx2%instr(gas)%esep**2)
        elseif (lEx2%instr(gas)%nsep /= error) then
            lEx2%instr(gas)%hsep = lEx2%instr(gas)%nsep
        elseif (lEx2%instr(gas)%esep /= error) then
            lEx2%instr(gas)%hsep = lEx2%instr(gas)%esep
        end if
    end do

    !> Understand software version (AGC (or RSSI) value is negative)
    !> LI-7200
    if (lEx2%agc72 < 0 .and. lEx2%agc72 /= error) then
        lEx2%agc72 =  - lEx2%agc72
    else
        co2_new_sw_ver = .true.
    end if
    !> LI-7500
    if (lEx2%agc75 < 0 .and. lEx2%agc75 /= error) then
        lEx2%agc75 =  - lEx2%agc75
    else
        co2_new_sw_ver = .true.
    end if

    !> Detrending method from integers to strings
    select case(lEx2%det_meth_int)
        case(0)
            lEx2%det_meth = 'ba'
        case(1)
            lEx2%det_meth = 'ld'
        case(2)
            lEx2%det_meth = 'rm'
        case(3)
            lEx2%det_meth = 'ew'
    end select

    !> Measurement type from integers to strings
    do gas = co2, gas4
        select case(lEx2%measure_type_int(gas))
            case(0)
                lEx2%measure_type(gas) = 'mixing_ratio'
            case(1)
                lEx2%measure_type(gas) = 'mole_fraction'
            case(2)
                lEx2%measure_type(gas) = 'molar_density'
        end select
    end do

    !> Daytime
    lEx2%daytime = lEx2%daytime_int == 1

    !> Legacy values to be later replaced with newer (left-hand sides) *********
    lEx2%file_records = lEx2%nr(1)
    lEx2%used_records = lEx2%nr(3)
    lEx2%tlag = lEx2%act_tlag
    lEx2%def_tlag = lEx2%act_tlag == lEx2%nom_tlag
    do var = u, gas4
        lEx2%var(var) = lEx2%stats%Cov(var, var)
    end do
    lEx2%cov_w(u) = lEx2%stats%cov(w, u)
    lEx2%cov_w(ts:gas4) = lEx2%stats%cov(w, ts:gas4)
end subroutine CompleteEssentials2