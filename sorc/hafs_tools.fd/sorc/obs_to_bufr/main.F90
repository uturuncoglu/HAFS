program obs_to_bufr_main

  !=======================================================================

  !$$$ PROGRAM DOCUMENTATION BLOCK
  
  ! obs_to_bufr :: obs_to_bufr_main
  ! Copyright (C) 2018 Henry R. Winterbottom

  ! Email: henry.winterbottom@noaa.gov

  ! This program is free software: you can redistribute it and/or
  ! modify it under the terms of the GNU General Public License as
  ! published by the Free Software Foundation, either version 3 of the
  ! License, or (at your option) any later version.

  ! This program is distributed in the hope that it will be useful,
  ! but WITHOUT ANY WARRANTY; without even the implied warranty of
  ! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  ! General Public License for more details.

  ! You should have received a copy of the GNU General Public License
  ! along with this program.  If not, see
  ! <http://www.gnu.org/licenses/>.

  ! Review the README, within the top-level directory, which provides
  ! relevant instructions and (any) references cited by algorithms
  ! within this software suite.

  !=======================================================================

  ! Define associated modules and subroutines

  use obs_to_bufr_interface

  ! Define interfaces and attributes for module routines
  
  implicit none
  
  !=======================================================================

  ! Compute local variables

  call obs_to_bufr()

  !=======================================================================

end program obs_to_bufr_main
