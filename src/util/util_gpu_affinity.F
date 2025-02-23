      subroutine util_setup_gpu_affinity
#ifdef USE_CUDA_AFFINITY
      use iso_fortran_env
      use cudafor
      use openacc
#include "errquit.fh"
#include "global.fh"
      integer(INT32) :: num_devices, use_ngpus, my_gpu
      integer :: ppn, node_rank, me
      character*255 :: char_use_ngpus
      integer(acc_device_kind) :: devicetype
      me = ga_nodeid()
      devicetype = NVIDIA
      !
      ! CUDA stuff
      !
      ! how many GPUs are detected
      err = cudaGetDeviceCount(num_devices)
      if (err.ne.0) call errquit('cudaGetDeviceCount',err,UNKNOWN_ERR)
      if (num_devices.lt.1) call errquit('No GPU found!',0,UNKNOWN_ERR)
      ! user prescribes how many to use
      call util_getenv('NWCHEM_OPENACC_USE_NGPUS',char_use_ngpus)
      if (me.eq.0) then
        print*,'CU NWCHEM_OPENACC_USE_NGPUS=',trim(char_use_ngpus)
      endif
      if (len(trim(char_use_ngpus)).gt.0) then
        read(char_use_ngpus,'(i255)') use_ngpus
        if (use_ngpus.gt.num_devices) then
          write(6,600) use_ngpus,num_devices
          use_ngpus = num_devices
        endif
  600   format('CU you asked for ',
     &         i2,' GPUs but only ',
     &         i2,' are present')
      else
        use_ngpus=num_devices
      endif
      ! GA PPN undercounts with ARMCI-MPI
      call util_getppn(ppn) ! THIS IS COLLECTIVE
      ! this assumes PPN is constant across nodes (reasonable)
      node_rank = modulo(me,ppn)
      ! assign GPUs to GA process ranks within a node (round-robin)
      my_gpu = modulo(node_rank,use_ngpus)
      if (me.lt.ppn) then
        write(6,700) 'node_rank',node_rank
        write(6,700) 'use_ngpus',use_ngpus
        write(6,700) 'ppn      ',ppn
        write(6,700) 'ga_nodeid',me
        write(6,700) 'my_gpu   ',my_gpu
  700   format('CU ',a12,'=',i5)
      endif
      err = cudaSetDevice(my_gpu)
      if (err.ne.0) call errquit('cudaSetDevice',my_gpu,UNKNOWN_ERR)
      call acc_set_device_num(my_gpu,devicetype)
#endif
      end subroutine util_setup_gpu_affinity
