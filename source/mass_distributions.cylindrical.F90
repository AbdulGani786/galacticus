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
  Implementation of an abstract mass distribution class for cylindrically symmetric distributions.
  !!}

  !![
  <massDistribution name="massDistributionCylindrical" abstract="yes">
   <description>An abstract mass distribution class for cylindrically symmetric distributions.</description>
  </massDistribution>
  !!]
  type, extends(massDistributionClass), abstract :: massDistributionCylindrical
     !!{
     Implementation of an abstract mass distribution class for cylindrically symmetric distributions.
     !!}
     private
   contains
     !![
     <methods>
       <method description="Returns the cylindrical radius enclosing half of the mass of the mass distribution."                                                                    method="radiusHalfMass"            />
       <method description="Returns the $n^\mathrm{th}$ moment of the integral of the surface density over radius, $\int_0^\infty \Sigma(\mathbf{x}) |x|^n \mathrm{d} \mathbf{x}$." method="surfaceDensityRadialMoment"/>
       <method description="Returns the circular velocity at the given {\normalfont \ttfamily radius}."                                                                             method="rotationCurve"             />
       <method description="Returns the gradient of the circular velocity at the given {\normalfont \ttfamily radius}."                                                             method="rotationCurveGradient"     />
       <method description="Returns the surface density at the given {\normalfont \ttfamily coordinates}."                                                                          method="surfaceDensity"            />
       <method description="Returns the spherically-averaged density at the given {\normalfont \ttfamily radius}."                                                                  method="densitySphericalAverage"   />
     </methods>
     !!]
     procedure                                                  :: symmetry                   => cylindricalSymmetry
     procedure(cylindricalRadiusHalfMass            ), deferred :: radiusHalfMass
     procedure(cylindricalSurfaceDensity            ), deferred :: surfaceDensity
     procedure(cylindricalRotationCurve             ), deferred :: rotationCurve
     procedure(cylindricalRotationCurveGradient     ), deferred :: rotationCurveGradient
     procedure(cylindricalSurfaceDensityRadialMoment), deferred :: surfaceDensityRadialMoment
     procedure(cylindricalDensitySphericalAverage   ), deferred :: densitySphericalAverage
  end type massDistributionCylindrical

  abstract interface

     double precision function cylindricalRadiusHalfMass(self,componentType,massType)
       !!{
       Interface for cylindrically symmetric mass distribution half mass radii functions.
       !!}
       import massDistributionCylindrical, enumerationComponentTypeType, enumerationMassTypeType
       class(massDistributionCylindrical ), intent(inout)           :: self
       type (enumerationComponentTypeType), intent(in   ), optional :: componentType
       type (enumerationMassTypeType     ), intent(in   ), optional :: massType
     end function cylindricalRadiusHalfMass

     double precision function cylindricalSurfaceDensity(self,coordinates,componentType,massType)
       !!{
       Interface for cylindrically symmetric mass distribution surface density functions.
       !!}
       import massDistributionCylindrical, coordinate, enumerationComponentTypeType, enumerationMassTypeType
       class(massDistributionCylindrical ), intent(inout)           :: self
       class(coordinate                  ), intent(in   )           :: coordinates
       type (enumerationComponentTypeType), intent(in   ), optional :: componentType
       type (enumerationMassTypeType     ), intent(in   ), optional :: massType
     end function cylindricalSurfaceDensity

     double precision function cylindricalRotationCurve(self,radius,componentType,massType)
       !!{
       Interface for cylindrically symmetric mass distribution rotation curve functions.
       !!}
       import massDistributionCylindrical, enumerationComponentTypeType, enumerationMassTypeType
       class           (massDistributionCylindrical ), intent(inout)           :: self
       double precision                              , intent(in   )           :: radius
       type            (enumerationComponentTypeType), intent(in   ), optional :: componentType
       type            (enumerationMassTypeType     ), intent(in   ), optional :: massType
     end function cylindricalRotationCurve

     double precision function cylindricalRotationCurveGradient(self,radius,componentType,massType)
       !!{
       Interface for cylindrically symmetric mass distribution rotation curve gradient functions.
       !!}
       import massDistributionCylindrical, enumerationComponentTypeType, enumerationMassTypeType
       class           (massDistributionCylindrical ), intent(inout)           :: self
       double precision                              , intent(in   )           :: radius
       type            (enumerationComponentTypeType), intent(in   ), optional :: componentType
       type            (enumerationMassTypeType     ), intent(in   ), optional :: massType
     end function cylindricalRotationCurveGradient

     double precision function cylindricalSurfaceDensityRadialMoment(self,moment,radiusMinimum,radiusMaximum,isInfinite,componentType,massType)
       !!{
       Interface for cylindrically symmetric mass distribution surface density radial moment functions.
       !!}
       import massDistributionCylindrical, enumerationComponentTypeType, enumerationMassTypeType
       class           (massDistributionCylindrical ), intent(inout)           :: self
       double precision                              , intent(in   )           :: moment
       double precision                              , intent(in   ), optional :: radiusMinimum, radiusMaximum
       logical                                       , intent(  out), optional :: isInfinite
       type            (enumerationComponentTypeType), intent(in   ), optional :: componentType
       type            (enumerationMassTypeType     ), intent(in   ), optional :: massType
     end function cylindricalSurfaceDensityRadialMoment

     double precision function cylindricalDensitySphericalAverage(self,radius,componentType,massType)
       !!{
       Interface for cylindrically symmetric mass distribution spherically-averaged density functions.
       !!}
       import massDistributionCylindrical, enumerationComponentTypeType, enumerationMassTypeType
       class           (massDistributionCylindrical ), intent(inout)           :: self
       double precision                              , intent(in   )           :: radius
       type            (enumerationComponentTypeType), intent(in   ), optional :: componentType
       type            (enumerationMassTypeType     ), intent(in   ), optional :: massType
     end function cylindricalDensitySphericalAverage

  end interface

contains

  function cylindricalSymmetry(self)
    !!{
    Returns symmetry label for mass distributions with cylindrical symmetry.
    !!}
    implicit none
    type (enumerationMassDistributionSymmetryType)                :: cylindricalSymmetry
    class(massDistributionCylindrical            ), intent(inout) :: self
    !$GLC attributes unused :: self

    cylindricalSymmetry=massDistributionSymmetryCylindrical
    return
  end function cylindricalSymmetry
