!! Copyright 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018,
!!           2019, 2020, 2021, 2022, 2023
!!    Andrew Benson <abenson@carnegiescience.edu>
!!
!! This file is part of Galacticus.
!!
!!    Galacticus is free software: you can redistribute it and/or modify
!!    it under the terms of the GNU General Public License as published by
!!    the Free Software Foundation, either version 3 of the License, or
!!    (at your option) any later version.
!!
!!    Galacticus is distributed in the hope that it will be useful,
!!    but WITHOUT ANY WARRANTY; without even the implied warranty of
!!    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
!!    GNU General Public License for more details.
!!
!!    You should have received a copy of the GNU General Public License
!!    along with Galacticus.  If not, see <http://www.gnu.org/licenses/>.

  !!{
  Implements a model of ram pressure stripping of hot halos based on the methods of \cite{font_colours_2008}.
  !!}

  use :: Hot_Halo_Mass_Distributions, only : hotHaloMassDistributionClass
  use :: Galactic_Structure         , only : galacticStructureClass

  !![
  <hotHaloRamPressureForce name="hotHaloRamPressureForceFont2008">
   <description>
    A hot halo ram pressure force class which follows the model of \cite{font_colours_2008}. Specifically, the ram pressure
    force is
    \begin{equation}
    \mathcal{F}_\mathrm{ram, hot, host} = \rho_\mathrm{hot, host}(r_\mathrm{peri}) v^2(r_\mathrm{peri}),
    \end{equation}
    where $\rho_\mathrm{hot, host}(r)$ is the hot halo density profile of the node's host halo, $v(r)$ is the orbital velocity
    of the node in that host, and $r_\mathrm{peri}$ is the pericentric radius of the node's orbit.
   </description>
  </hotHaloRamPressureForce>
  !!]
  type, extends(hotHaloRamPressureForceClass) :: hotHaloRamPressureForceFont2008
     !!{
     Implementation of a hot halo ram pressure force class which follows the model of \cite{font_colours_2008}.
     !!}
     private
     class(hotHaloMassDistributionClass), pointer :: hotHaloMassDistribution_ => null()
     class(galacticStructureClass      ), pointer :: galacticStructure_       => null()
   contains
     final     ::          font2008Destructor
     procedure :: force => font2008Force
  end type hotHaloRamPressureForceFont2008

  interface hotHaloRamPressureForceFont2008
     !!{
     Constructors for the {\normalfont \ttfamily font2008} hot halo ram pressure force class.
     !!}
     module procedure font2008ConstructorParameters
     module procedure font2008ConstructorInternal
  end interface hotHaloRamPressureForceFont2008

contains

  function font2008ConstructorParameters(parameters) result(self)
    !!{
    Constructor for the {\normalfont \ttfamily font2008} hot halo ram pressure force class which builds the object from a parameter set.
    !!}
    use :: Input_Parameters, only : inputParameter, inputParameters
    implicit none
    type (hotHaloRamPressureForceFont2008)                :: self
    type (inputParameters                ), intent(inout) :: parameters
    class(hotHaloMassDistributionClass   ), pointer       :: hotHaloMassDistribution_
    class(galacticStructureClass         ), pointer       :: galacticStructure_

    !![
    <objectBuilder class="hotHaloMassDistribution" name="hotHaloMassDistribution_" source="parameters"/>
    <objectBuilder class="galacticStructure"       name="galacticStructure_"       source="parameters"/>
    !!]
    self=hotHaloRamPressureForceFont2008(hotHaloMassDistribution_,galacticStructure_)
    !![
    <inputParametersValidate source="parameters"/>
    <objectDestructor name="hotHaloMassDistribution_"/>
    <objectDestructor name="galacticStructure_"      />
    !!]
    return
  end function font2008ConstructorParameters

  function font2008ConstructorInternal(hotHaloMassDistribution_,galacticStructure_) result(self)
    !!{
    Internal constructor for the {\normalfont \ttfamily font2008} hot halo ram pressure force class.
    !!}
    implicit none
    type (hotHaloRamPressureForceFont2008)                        :: self
    class(hotHaloMassDistributionClass   ), intent(in   ), target :: hotHaloMassDistribution_
    class(galacticStructureClass         ), intent(in   ), target :: galacticStructure_
    !![
    <constructorAssign variables="*hotHaloMassDistribution_, *galacticStructure_"/>
    !!]

    return
  end function font2008ConstructorInternal

  subroutine font2008Destructor(self)
    !!{
    Destructor for the {\normalfont \ttfamily font2008} hot halo ram pressure force class.
    !!}
    implicit none
    type(hotHaloRamPressureForceFont2008), intent(inout) :: self

    !![
    <objectDestructor name="self%hotHaloMassDistribution_"/>
    <objectDestructor name="self%galacticStructure_"      />
    !!]
    return
  end subroutine font2008Destructor

  double precision function font2008Force(self,node)
    !!{
    Return a ram pressure force due to the hot halo using the model of \cite{font_colours_2008}.
    !!}
    use :: Galacticus_Nodes, only : nodeComponentSatellite                          , treeNode
    use :: Kepler_Orbits   , only : keplerOrbit
    use :: Satellite_Orbits, only : Satellite_Orbit_Extremum_Phase_Space_Coordinates, extremumPericenter
    implicit none
    class           (hotHaloRamPressureForceFont2008), intent(inout) :: self
    type            (treeNode                       ), intent(inout) :: node
    class           (nodeComponentSatellite         ), pointer       :: satellite
    type            (treeNode                       ), pointer       :: nodeHost
    type            (keplerOrbit                    )                :: orbit
    double precision                                                 :: radiusOrbital, velocityOrbital

    ! Find the host node.
    nodeHost  => node     %parent
    ! Get the satellite component.
    satellite => node     %satellite  ()
    ! Get the orbit for this node.
    orbit     =  satellite%virialOrbit()
    ! Get the orbital radius and velocity at pericenter.
    call Satellite_Orbit_Extremum_Phase_Space_Coordinates(nodeHost,orbit,extremumPericenter,radiusOrbital,velocityOrbital,self%galacticStructure_)
    ! Find the ram pressure force at pericenter.
    font2008Force=+self%hotHaloMassDistribution_%density(nodeHost,radiusOrbital) &
         &        *velocityOrbital**2
    return
  end function font2008Force
