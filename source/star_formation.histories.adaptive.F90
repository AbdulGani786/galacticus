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
  Contains a module which implements a star formation histories class which records star formation in adaptively sized time
  bins and split by metallicity.
  !!}

  use :: Output_Times, only : outputTimes, outputTimesClass

  type :: timeIntervals
     !!{
     A type used to store the end times of intervals used for star formation history storage, along with a map of indices which
     describes how to merge intervals from the previous output time.
     !!}
     double precision          , allocatable, dimension(:) :: time
     integer         (c_size_t), allocatable, dimension(:) :: indexMap
  end type timeIntervals  
  
  !![
  <starFormationHistory name="starFormationHistoryAdaptive">
   <description>
    A star formation histories class which records star formation split by metallicity. The star formation history is tabulated
    on a grid of time and metallicity. A minimum size for the time bins is specified via $\Delta t=${\normalfont \ttfamily
    [timeStepMinimum]}, and a maximum number of time bins allowed is specified via {\normalfont \ttfamily
    [countTimeStepsMaximum]}. For the first output time, a set of timesteps starting from $t=0$ to the output time is generated
    with size $\Delta t$. If the number of steps exceeds {\normalfont \ttfamily [countTimeStepsMaximum]} then one pair of
    consecutive steps are merged. The pair merged is chosen to minimize the global increase in the metric
    $(t_{i+1}-t_i)/(t\mathrm{out}-t_i)$ where $t_i$ are the current timesteps and $t_\mathrm{out}$ is the output time. This
    process is repeated until the number of timesteps is reduced to {\normalfont \ttfamily [countTimeStepsMaximum]}. This
    results in timesteps distributed approximately uniformly in the logarithm of the age of the timestep.
  
    For subsequent output times, the prior set of times is first extended, in steps of $\Delta t$, to reach the new output
    time, and then, if necessary, the same timestep consolidation algorithm is applied to reduce the number of steps to
    {\normalfont \ttfamily [countTimeStepsMaximum]}. Any accumulated star formation in the time bins used for the previous
    output time are accumulated over each consolidated pair of bins.
  
    This approach ensures that the number of timesteps never exceeds {\normalfont \ttfamily [countTimeStepsMaximum]}, results
    in timesteps that are small close to the output time, but increase (approximately logarithmically) for times earlier than
    the output time, and allows simple (interpolation-free) consolidation of accumulate star formation from the previous output
    time's timesteps to those of the current output time.
  
    Typically, the metallicity binning is arranged logarithmically in metallicity with {\normalfont \ttfamily
    [countMetallicities]} bins between {\normalfont \ttfamily [metallicityMinimum]} and {\normalfont \ttfamily
    [metallicityMaximum]} (specified in Solar units). Note that the metallicity associated with each bin is the minimum
    metallicity for that bin (the maximum being the metallicity value associated with the next bin, except for the final bin
    which extends to infinite metallicity). If {\normalfont \ttfamily [countMetallicities]}$=0$ is set, then the star formation
    history is not split by metallicity (i.e. a single metallicity bin encompassing all metallicities from zero to infinity is
    used). Alternatively, specific metallicity bin boundaries can be set via the {\normalfont \ttfamily
    [metallicityBoundaries]} parameter---a final boundary corresponding to infinity is always added automatically.
  
    Star formation histories are output as follows:
    \begin{verbatim}
    GROUP "starFormationHistories" {
       COMMENT "Star formation history data."
       GROUP "Output1" {
          COMMENT "Star formation histories for all trees at each output."
          DATASET "diskStarFormationHistory" {
          COMMENT "Star formation history of the disk component."
             DATATYPE  H5T_IEEE_F64LE
             DATASPACE  SIMPLE { ( [countMetallicities], [countTimes], [countGalaxies] ) }
          }
          DATASET "metallicity" {
          COMMENT "Metallicities at which the star formation history is tabulated [Zsun]."
             DATATYPE  H5T_IEEE_F64LE
             DATASPACE  SIMPLE { ( [countMetallicities] ) }
          }
          DATASET "spheroidStarFormationHistory" {
          COMMENT "Star formation history of the spheroid component."
             DATATYPE  H5T_IEEE_F64LE
             DATASPACE  SIMPLE { ( [countMetallicities], [countTimes], [countGalaxies] ) }
          }
          DATASET "time" {
          COMMENT "Times at which the star formation history is tabulated [Gyr]."
             DATATYPE  H5T_IEEE_F64LE
             DATASPACE  SIMPLE { ( [countTimes] ) ) }
          }
       }
       GROUP "Output2" {
        .
        .
        .
       }
    }
    \end{verbatim}
   </description>
  </starFormationHistory>
  !!]
  type, extends(starFormationHistoryClass) :: starFormationHistoryAdaptive
     !!{
     A star formation histories class which records star formation split by metallicity.
     !!}
     private
     class           (outputTimesClass), pointer                         :: outputTimes_               => null()
     double precision                                                    :: timeStepMinimum                     , metallicityMaximum, &
          &                                                                 metallicityMinimum
     integer         (c_size_t        )                                  :: countTimeStepsMaximum               , countMetallicities, &
          &                                                                 countOutputBuffer
     double precision                  , allocatable, dimension(:      ) :: metallicityTable
     type            (timeIntervals   ), allocatable, dimension(:      ) :: intervals
     double precision                  , allocatable, dimension(:,:,:,:) :: starFormationHistoryBuffer
     integer         (c_size_t        ), allocatable, dimension(:      ) :: indexOutputBuffer                   , indexOutput
   contains
     !![
     <methods>
      <method description="Output all star formation history data accumulated in the output buffers." method="outputBuffers"/>
     </methods>
     !!]
     final     ::                                adaptiveDestructor
     procedure :: create                      => adaptiveCreate
     procedure :: rate                        => adaptiveRate
     procedure :: output                      => adaptiveOutput
     procedure :: outputFlush                 => adaptiveOutputFlush
     procedure :: scales                      => adaptiveScales
     procedure :: outputBuffers               => adaptiveOutputBuffers
     procedure :: metallicityBoundaries       => adaptiveMetallicityBoundaries
     procedure :: perOutputTabulationIsStatic => adaptivePerOutputTabulationIsStatic
     procedure :: descriptor                  => adaptiveDescriptor
  end type starFormationHistoryAdaptive

  interface starFormationHistoryAdaptive
     !!{
     Constructors for the ``adaptive'' star formation history class.
     !!}
     module procedure adaptiveConstructorParameters
     module procedure adaptiveConstructorInternal
  end interface starFormationHistoryAdaptive

  ! Effective infinite metallicity.
  double precision, parameter :: metallicityInfinite=huge(1.0d0)

contains

  function adaptiveConstructorParameters(parameters) result(self)
    !!{
    Constructor for the ``adaptive'' star formation history class which takes a parameter set as input.
    !!}
    use :: Input_Parameters, only : inputParameter, inputParameters
    implicit none
    type            (starFormationHistoryAdaptive)                              :: self
    type            (inputParameters             ), intent(inout)               :: parameters
    class           (outputTimesClass            ), pointer                     :: outputTimes_
    double precision                              , allocatable  , dimension(:) :: metallicityBoundaries
    double precision                                                            :: timeStepMinimum      , metallicityMinimum   , &
         &                                                                         metallicityMaximum
    integer         (c_size_t)                                                  :: countMetallicities   , countTimeStepsMaximum, &
          &                                                                        countOutputBuffer

    !![
    <inputParameter>
      <name>timeStepMinimum</name>
      <defaultValue>0.01d0</defaultValue>
      <description>The minimum time step to use in tabulations of star formation histories [Gyr].</description>
      <source>parameters</source>
    </inputParameter>
    <inputParameter>
      <name>countTimeStepsMaximum</name>
      <defaultValue>10_c_size_t</defaultValue>
      <description>The maximum number of timesteps to track in any star formation history.</description>
      <source>parameters</source>
    </inputParameter>
    !!]
    if (parameters%isPresent('metallicityBoundaries')) then
       countMetallicities=parameters%count('metallicityBoundaries')
       allocate(metallicityBoundaries(countMetallicities+1))
       !![
       <inputParameter>
         <name>metallicityBoundaries</name>
         <description>The metallicities corresponding to boundaries between metallicity bins to use when tabulating star formation histories.</description>
         <source>parameters</source>
         <variable>metallicityBoundaries(1:size(metallicityBoundaries)-1)</variable>
         <type>real</type>
         <cardinality>0..*</cardinality>
       </inputParameter>
       !!]
       metallicityBoundaries(size(metallicityBoundaries))=metallicityInfinite
    else
       !![
       <inputParameter>
         <name>countMetallicities</name>
         <defaultValue>10_c_size_t</defaultValue>
         <description>The number of bins in metallicity to use when tabulating star formation histories.</description>
         <source>parameters</source>
       </inputParameter>
       <inputParameter>
         <name>metallicityMinimum</name>
         <defaultValue>1.0d-4</defaultValue>
         <description>The upper limit to the metallicity in the lowest metallicity bin when tabulating star formation histories [Solar units].</description>
         <source>parameters</source>
       </inputParameter>
       <inputParameter>
         <name>metallicityMaximum</name>
         <defaultValue>1.0d+1</defaultValue>
         <description>The upper limit to the metallicity in the highest metallicity bin when tabulating star formation histories [Solar units].</description>
         <source>parameters</source>
       </inputParameter>
       !!]
    end if
    !![
    <inputParameter>
      <name>countOutputBuffer</name>
      <defaultValue>100_c_size_t</defaultValue>
      <description>The number of galaxies to hold in the output buffer.</description>
      <source>parameters</source>
    </inputParameter>
    <objectBuilder class="outputTimes" name="outputTimes_" source="parameters"/>
    <conditionalCall>
     <call>self=starFormationHistoryAdaptive(outputTimes_,countOutputBuffer,timeStepMinimum,countTimeStepsMaximum{conditions})</call>
     <argument name="metallicityBoundaries" value="metallicityBoundaries" condition="     parameters%isPresent('metallicityBoundaries')"/>
     <argument name="countMetallicities"    value="countMetallicities"    condition=".not.parameters%isPresent('metallicityBoundaries')"/>
     <argument name="metallicityMinimum"    value="metallicityMinimum"    condition=".not.parameters%isPresent('metallicityBoundaries')"/>
     <argument name="metallicityMaximum"    value="metallicityMaximum"    condition=".not.parameters%isPresent('metallicityBoundaries')"/>
    </conditionalCall>
    <inputParametersValidate source="parameters"/>
    <objectDestructor name="outputTimes_"/>
    !!]
    return
  end function adaptiveConstructorParameters

  function adaptiveConstructorInternal(outputTimes_,countOutputBuffer,timeStepMinimum,countTimeStepsMaximum,metallicityBoundaries,countMetallicities,metallicityMinimum,metallicityMaximum) result(self)
    !!{
    Internal constructor for the ``adaptive'' star formation history class.
    !!}
    use :: Error                     , only : Error_Report
    use :: Galactic_Structure_Options, only : componentTypeMax, componentTypeMin
    use :: Numerical_Ranges          , only : Make_Range      , rangeTypeLogarithmic
    implicit none
    type            (starFormationHistoryAdaptive)                                        :: self
    double precision                              , intent(in   ), dimension(:), optional :: metallicityBoundaries
    double precision                              , intent(in   )              , optional :: metallicityMinimum   , metallicityMaximum
    double precision                              , intent(in   )                         :: timeStepMinimum
    integer         (c_size_t                    ), intent(in   )                         :: countTimeStepsMaximum, countOutputBuffer
    integer         (c_size_t                    ), intent(in   )              , optional :: countMetallicities
    class           (outputTimesClass            ), intent(in   ), target                 :: outputTimes_
    double precision                              , allocatable  , dimension(:)           :: timesNew             , timesNewTmp
    integer         (c_size_t                    ), allocatable  , dimension(:)           :: indexMap             , indexMapTmp
    integer         (c_size_t                    )                                        :: iStart               , countTimesNew      , &
         &                                                                                   iNew                 , iOutput            , &
         &                                                                                   iInterval            , iCombine
    double precision                                                                      :: timeStart            , timeEnd            , &
         &                                                                                   metric               , metricChangeMinimum, &
         &                                                                                   metricChange         , metricMinimumGlobal
    !![
    <constructorAssign variables="countOutputBuffer, timeStepMinimum, countTimeStepsMaximum, metallicityMinimum, metallicityMaximum, countMetallicities, *outputTimes_"/>
    !!]

    ! Validate metallicity argument and construct the table of metallicities.
    if (present(metallicityBoundaries)) then
       if     (                                &
            &   present(countMetallicities   ) &
            &  .or.                            &
            &   present(metallicityMinimum   ) &
            &  .or.                            &
            &   present(metallicityMaximum   ) &
            & ) call Error_Report('specify either a list of metallicity boundaries, or a range, not both'//{introspection:location})
       allocate(self%metallicityTable(size(metallicityBoundaries)))
       self%metallicityTable  =     metallicityBoundaries
       self%countMetallicities=size(metallicityBoundaries)-1
    else
       if     (                                &
            &   present(metallicityBoundaries) &
            & ) call Error_Report('specify either a list of metallicity boundaries, or a range, not both'//{introspection:location})
       if     (                                     &
            &   .not.present(countMetallicities   ) &
            &  .or.                                 &
            &   .not.present(metallicityMinimum   ) &
            &  .or.                                 &
            &   .not.present(metallicityMaximum   ) &
            & ) call Error_Report('metallicity range is incompletely specified'//{introspection:location})
       ! Construct a table of metallicities at which to tabulate. Add an extra bin since we want to catch all metallicities,
       ! including those below and above the maximum. A single bin is not allowed, but zero bins implies that no metallicity
       ! resolution is required.
       select case (countMetallicities)
       case (:-1,1)
          call Error_Report('number of bins must be 0, or greater than 1'//{introspection:location})
       case default
          allocate(self%metallicityTable(countMetallicities+1))
          if (countMetallicities > 1) self%metallicityTable(1:countMetallicities)=Make_Range(metallicityMinimum,metallicityMaximum,int(countMetallicities),rangeType=rangeTypeLogarithmic)
          self%metallicityTable(countMetallicities+1)=metallicityInfinite
       end select
    end if
    ! Construct the time bins and rebinning strategy to be used for each output.
    allocate(self%intervals(self%outputTimes_%count()))
    do iOutput=1,self%outputTimes_%count()
       ! Our start time is either the minimum timestep size (for the first output), or the end time of the timesteps of the
       ! previous output, plus the minimum timestep.
       if (iOutput == 1) then
          timeStart=self%timeStepMinimum
       else
          timeStart=self%timeStepMinimum+self%intervals(iOutput-1)%time(size(self%intervals(iOutput-1)%time))
       end if
       timeEnd      =self%outputTimes_%time(iOutput)
       countTimesNew=int((timeEnd-timeStart)/self%timeStepMinimum)+1
       ! Construct new timesteps to span the the current output time.
       !! Allocate sufficient space for timesteps and copy in the previous timesteps.
       if (iOutput == 1) then
          allocate(timesNew(countTimesNew))
          allocate(indexMap(countTimesNew))
          iStart                                          =                                     1
       else
          allocate(timesNew(countTimesNew+size(self%intervals(iOutput-1)%time)))
          allocate(indexMap(countTimesNew+size(self%intervals(iOutput-1)%time)))
          timesNew(1:size(self%intervals(iOutput-1)%time))=     self%intervals(iOutput-1)%time
          iStart                                          =size(self%intervals(iOutput-1)%time)+1
       end if
       !! Construct a mapping of indices between the current and previous interval.
       indexMap=0_c_size_t
       do iInterval=1,iStart-1
          indexMap(iInterval)=iInterval
       end do
       !! Set times for the new timesteps.
       do iNew=0,countTimesNew-1
          timesNew(iNew+iStart)=timeStart+dble(iNew)*self%timeStepMinimum
       end do
       !! Iteratively remove timesteps until we have no more than the permitted maximum.
       do while (size(timesNew) > self%countTimeStepsMaximum)
          ! Evaluate our heuristic metric for which steps to combine. Our metric is that the logarithmic interval size, Δt/age
          ! should be minimized. We therefore find the global minimum of this metric across all current intervals, and then find the
          ! consecutive pair of intervals which, when combined, result in the smallest increase in the global minimum.
          !! First, find the global minimum value of our metric.
          metricMinimumGlobal=huge(0.0d0)
          do iInterval=1,size(timesNew)
             timeEnd=timesNew(iInterval)
             if (iInterval == 1) then
                timeStart=0.0d0
             else
                timeStart=timesNew(iInterval-1)
             end if
             metric             =+(                  timeEnd         -timeStart) &
                  &              /(self%outputTimes_%time   (iOutput)-timeStart)
             metricMinimumGlobal=min(metric,metricMinimumGlobal)
          end do
          !! Determine which consecutive pair of intervals which, when combined, will result in the minimum increase in the global
          !! minimum metric
          iCombine           =-1
          metricChangeMinimum=huge(0.0d0)
          do iInterval=2,size(timesNew)
             ! Metric if combined.
             timeEnd=timesNew(iInterval)
             if (iInterval == 2) then
                timeStart=0.0d0
             else
                timeStart=timesNew(iInterval-2)
             end if
             metric=+(                  timeEnd         -timeStart) &
                  & /(self%outputTimes_%time   (iOutput)-timeStart)
             ! Change in the global metric minimum
             metricChange=+metric              &
                  &       -metricMinimumGlobal
             if (metricChange < metricChangeMinimum) then
                metricChangeMinimum=metricChange
                iCombine=iInterval
             end if
          end do
          if (iCombine == -1) call Error_Report('no interval found - this should not happen'//{introspection:location})
          ! Combine the intervals.
          allocate(timesNewTmp(size(timesNew)-1))
          allocate(indexMapTmp(size(timesNew)-1))
          if (iCombine > 2) then
             timesNewTmp(1:iCombine-2)=timesNew(1:iCombine-2)
             indexMapTmp(1:iCombine-2)=indexMap(1:iCombine-2)
          end if
          timesNewTmp(iCombine-1:size(timesNewTmp))=timesNew(iCombine:size(timesNew))
          indexMapTmp(iCombine-1:size(indexMapTmp))=indexMap(iCombine:size(indexMap))
          ! Capture the final index if necessary.
          if (iCombine > 1 .and. indexMap(iCombine) == 0) indexMapTmp(iCombine-1)=indexMap(iCombine-1)
          deallocate(timesNew)
          deallocate(indexMap)
          call move_alloc(timesNewTmp,timesNew)
          call move_alloc(indexMapTmp,indexMap)
       end do
       ! Number of intervals is now equal to or less than the maximum permitted. Store these intervals, and the map from the
       ! previous output's intervals.
       call move_alloc(timesNew,self%intervals(iOutput)%time    )
       call move_alloc(indexMap,self%intervals(iOutput)%indexMap)
    end do
    ! Construct output buffers.
    allocate(self%starFormationHistoryBuffer(self%countTimeStepsMaximum,size(self%metallicityTable),self%countOutputBuffer,componentTypeMin:componentTypeMax))
    allocate(self%         indexOutputBuffer(                                                                              componentTypeMin:componentTypeMax))
    allocate(self%         indexOutput      (                                                                              componentTypeMin:componentTypeMax))
    self%indexOutput      =-1_c_size_t
    self%indexOutputBuffer= 0_c_size_t
    return
  end function adaptiveConstructorInternal

  subroutine adaptiveDestructor(self)
    !!{
    Destructor for the {\normalfont \ttfamily adaptive} star formation histories class.
    !!}
    implicit none
    type(starFormationHistoryAdaptive), intent(inout) :: self

    !![
    <objectDestructor name="self%outputTimes_"/>
    !!]
    return
  end subroutine adaptiveDestructor

  subroutine adaptiveCreate(self,node,historyStarFormation,timeBegin)
    !!{
    Create the history required for storing star formation history.
    !!}
    use :: Galacticus_Nodes, only : nodeComponentBasic
    implicit none
    class           (starFormationHistoryAdaptive), intent(inout) :: self
    type            (treeNode                    ), intent(inout) :: node
    type            (history                     ), intent(inout) :: historyStarFormation
    double precision                              , intent(in   ) :: timeBegin
    class           (nodeComponentBasic          ), pointer       :: basic
    integer         (c_size_t                    )                :: indexOutput
    double precision                                              :: timeNext
    !$GLC attributes unused :: timeBegin

    ! Get the time and index of the next output
    basic    => node             %basic   (                                                )
    timeNext =  self%outputTimes_%timeNext(timeCurrent=basic%time(),indexOutput=indexOutput)
    ! Create the appropriate history.
    call historyStarFormation%create(int(self%countMetallicities+1),size(self%intervals(indexOutput)%time))
    historyStarFormation%time=self%intervals(indexOutput)%time
    return
  end subroutine adaptiveCreate

  subroutine adaptiveRate(self,node,historyStarFormation,abundancesFuel,rateStarFormation)
    !!{
    Set the rate the star formation history for {\normalfont \ttfamily node}.
    !!}
    use :: Abundances_Structure, only : abundances        , metallicityTypeLinearByMassSolar
    use :: Arrays_Search       , only : searchArray
    use :: Galacticus_Nodes    , only : nodeComponentBasic, treeNode
    use :: Error               , only : Error_Report
    implicit none
    class           (starFormationHistoryAdaptive), intent(inout) :: self
    type            (treeNode                    ), intent(inout) :: node
    type            (history                     ), intent(inout) :: historyStarFormation
    type            (abundances                  ), intent(in   ) :: abundancesFuel
    double precision                              , intent(in   ) :: rateStarFormation
    class           (nodeComponentBasic          ), pointer       :: basic
    integer         (c_size_t                    )                :: iHistory            , iMetallicity
    double precision                                              :: fuelMetallicity     , time

    ! Check if history exists.
    if (historyStarFormation%exists()) then
       basic => node %basic()
       time  =  basic%time ()
       ! Find the point in the table at which to accumulate the star formation rate.
       iHistory=searchArray(historyStarFormation%time,time)+1
       ! Find the metallicity bin to accumulate to.
       if    (self%countMetallicities    == 0              ) then
          iMetallicity   =                                                  +1
       else
          fuelMetallicity=abundancesFuel%metallicity(metallicityType=metallicityTypeLinearByMassSolar)
          if (self%metallicityTable  (1) >  fuelMetallicity) then
             iMetallicity=                                                  +1
          else
             iMetallicity=searchArray(self%metallicityTable,fuelMetallicity)+1
          end if
       end if
       ! Accumulate to the appropriate time.
       historyStarFormation%data(iHistory,iMetallicity)=rateStarFormation
    else
       ! No history exists - this is acceptable only if the star formation rate is zero.
       if (rateStarFormation > 0.0d0) call Error_Report('non-zero star formation rate, but star formation history is uninitialized'//{introspection:location})
    end if
    return
  end subroutine adaptiveRate

  subroutine adaptiveOutput(self,node,nodePassesFilter,historyStarFormation,indexOutput,indexTree,componentType,treeLock)
    !!{
    Output the star formation history for {\normalfont \ttfamily node}.
    !!}
    implicit none
    class           (starFormationHistoryAdaptive), intent(inout)         :: self
    type            (treeNode                    ), intent(inout), target :: node
    logical                                       , intent(in   )         :: nodePassesFilter
    type            (history                     ), intent(inout)         :: historyStarFormation
    integer         (c_size_t                    ), intent(in   )         :: indexOutput
    integer         (kind=kind_int8              ), intent(in   )         :: indexTree
    type            (enumerationComponentTypeType), intent(in   )         :: componentType
    type            (ompLock                     ), intent(inout)         :: treeLock
    integer         (c_size_t                    )                        :: iStart              , iEnd, &
         &                                                                   i
    type            (history                     )                        :: newHistory

    ! If the node is to be output, accumulate its star formation history to the output buffers.
    if (nodePassesFilter) then
       ! If the current output is not the same as the previous, output any buffered data.
       if (self%indexOutput(componentType%ID) /= indexOutput) call self%outputBuffers(componentType,treeLock)
       self%indexOutput(componentType%ID)=indexOutput
       ! Accumulate the current node to the output buffer.
       self   %indexOutputBuffer         (                                                                                    componentType%ID)=self                %indexOutputBuffer(componentType%ID)+1_c_size_t
       if (historyStarFormation%exists()) then                                                                                          
          self%starFormationHistoryBuffer(1:size(self%intervals(indexOutput)%time),:,self%indexOutputBuffer(componentType%ID),componentType%ID)=historyStarFormation%data             (:,:             )
       else                                                                                                                             
          self%starFormationHistoryBuffer(1:size(self%intervals(indexOutput)%time),:,self%indexOutputBuffer(componentType%ID),componentType%ID)=0.0d0
       end if
       ! If the buffer is full, output it.
       if (self%indexOutputBuffer(componentType%ID) == self%countOutputBuffer) call self%outputBuffers(componentType,treeLock)
    end if
    ! If another output exists map the existing star formation history to the time bins of the next output.
    if (historyStarFormation%exists() .and. indexOutput < size(self%intervals)) then
       call newHistory%create(int(self%countMetallicities+1),size(self%intervals(indexOutput+1)%time))
       newHistory%time=self%intervals(indexOutput+1)%time
       do i=1,size(self%intervals(indexOutput+1)%indexMap)
          if (self%intervals(indexOutput+1)%indexMap(i) == 0) then
             newHistory%data(i,:)=0.0d0
          else
             if (i == 1) then
                iStart           =                                           +1
             else
                iStart           =self%intervals(indexOutput+1)%indexMap(i-1)+1
             end if
             iEnd                =self%intervals(indexOutput+1)%indexMap(i  )
             newHistory%data(i,:)=sum(historyStarFormation%data(iStart:iEnd,:),dim=1)
          end if
       end do
       call historyStarFormation%destroy()
       historyStarFormation=newHistory
       call newHistory%destroy()
    end if
    return
  end subroutine adaptiveOutput

  subroutine adaptiveOutputFlush(self,componentType,treeLock)
    !!{
    Flush any buffered star formation history data.
    !!}
    implicit none
    class(starFormationHistoryAdaptive), intent(inout) :: self
    type (enumerationComponentTypeType), intent(in   ) :: componentType
    type (ompLock                     ), intent(inout) :: treeLock

    call self%outputBuffers(componentType,treeLock)     
    return
  end subroutine adaptiveOutputFlush
  
  subroutine adaptiveScales(self,historyStarFormation,massStellar,abundancesStellar)
    !!{
    Set the scalings for error control on the absolute values of star formation histories.
    !!}
    implicit none
    class           (starFormationHistoryAdaptive), intent(inout)               :: self
    double precision                              , intent(in   )               :: massStellar
    type            (abundances                  ), intent(in   )               :: abundancesStellar
    type            (history                     ), intent(inout)               :: historyStarFormation
    double precision                              , parameter                   :: massStellarMinimum  =1.0d0
    double precision                              , allocatable  , dimension(:) :: timeSteps
    integer         (c_size_t                    )                              :: iMetallicity
    !$GLC attributes unused :: abundancesStellar

    if (.not.historyStarFormation%exists()) return
    call historyStarFormation%timeSteps(timeSteps)
    forall(iMetallicity=1:self%countMetallicities+1)
       historyStarFormation%data(:,iMetallicity)=max(massStellar,massStellarMinimum)/timeSteps
    end forall
    deallocate(timeSteps)
    return
  end subroutine adaptiveScales

  subroutine adaptiveOutputBuffers(self,componentType,treeLock)
    !!{
    Output all star formation history data in the output buffers.
    !!}
    use :: Output_HDF5               , only : outputFile
    use :: Galactic_Structure_Options, only : enumerationComponentTypeDecode
    use :: HDF5_Access               , only : hdf5Access
    use :: IO_HDF5                   , only : hdf5Object
    use :: String_Handling           , only : operator(//)
    implicit none
    class(starFormationHistoryAdaptive), intent(inout) :: self
    type (enumerationComponentTypeType), intent(in   ) :: componentType
    type (ompLock                     ), intent(inout) :: treeLock
    type (hdf5Object                  )                :: historyGroup   , outputGroup
    type (varying_string              )                :: nameOutputGroup, nameStarFormationHistory
    
    ! Return immediately if there is no buffered output.
    if (self%indexOutputBuffer(componentType%ID) <= 0_c_size_t) return
    if (.not.treeLock%ownedByThread()) call treeLock%set()
    nameOutputGroup         =var_str                       ("Output"                           )//self%indexOutput(componentType%ID)
    nameStarFormationHistory=enumerationComponentTypeDecode(componentType,includePrefix=.false.)//"StarFormationHistory"
    !$ call hdf5Access%set()
    historyGroup=outputFile  %openGroup("starFormationHistories","Star formation history data."                          )
    outputGroup =historyGroup%openGroup(char(nameOutputGroup)   ,"Star formation histories for all trees at each output.")
    if (.not.outputGroup%hasDataset('time')) then
       call outputGroup%writeDataset(self%intervals(self%indexOutput(componentType%ID))%time            ,"time"       ,"Times at which the star formation history is tabulated [Gyr]."       )
       call outputGroup%writeDataset(self                                              %metallicityTable,"metallicity","Metallicities at which the star formation history is tabulated [Z☉].")
    end if
    call outputGroup%writeDataset(                                                                                                                                                                                &
         &                                        self%starFormationHistoryBuffer(1:size(self%intervals(self%indexOutput(componentType%ID))%time),:,1:self%indexOutputBuffer(componentType%ID),componentType%ID), &
         &                                                                          char(nameStarFormationHistory                                           )                                                   , &
         &                                        "Star formation history of the "//char(enumerationComponentTypeDecode(componentType,includePrefix=.false.))//" component."                                    , &
         &                        appendTo       =.true.                                                                                                                                                        , &
         &                        appendDimension=3                                                                                                                                                             , &
         &                        chunkSize      =self%countOutputBuffer                                                                                                                                          &
         &                       )
    call  outputGroup%close()
    call historyGroup%close()
    !$ call hdf5Access%unset()
    self%indexOutputBuffer(componentType%ID)=0_c_size_t
    return
  end subroutine adaptiveOutputBuffers
  
  function adaptiveMetallicityBoundaries(self)
    !!{
    Return the boundaries of the metallicities used in this tabulation.
    !!}
    implicit none
    double precision                              , allocatable  , dimension(:) :: adaptiveMetallicityBoundaries
    class           (starFormationHistoryAdaptive), intent(inout)               :: self

    allocate(adaptiveMetallicityBoundaries(0:size(self%metallicityTable)-1))
    adaptiveMetallicityBoundaries(0:size(self%metallicityTable)-1)=self%metallicityTable(1:size(self%metallicityTable))
    return
  end function adaptiveMetallicityBoundaries

  logical function adaptivePerOutputTabulationIsStatic(self)
    !!{
    Return true since the tabulation (in time and metallicity) is static (independent of node) per output.
    !!}
    implicit none
    class(starFormationHistoryAdaptive), intent(inout) :: self

    adaptivePerOutputTabulationIsStatic=.true.
    return
  end function adaptivePerOutputTabulationIsStatic

  subroutine adaptiveDescriptor(self,descriptor,includeClass)
    !!{
    Return an input parameter list descriptor which could be used to recreate this object.
    !!}
    use :: Input_Parameters  , only : inputParameters
    use :: ISO_Varying_String, only : assignment(=)  , char, operator(//)
    implicit none
    class    (starFormationHistoryAdaptive), intent(inout)           :: self
    type     (inputParameters             ), intent(inout)           :: descriptor
    logical                                , intent(in   ), optional :: includeClass
    character(len=18                      )                          :: parameterLabel
    type     (inputParameters             )                          :: parameters
    integer                                                          :: i
    type     (varying_string              )                          :: metallicityBoundariesLabel

    if (.not.present(includeClass).or.includeClass) call descriptor%addParameter('starFormationHistory','adaptive')
    parameters=descriptor%subparameters('starFormationHistory')
    write (parameterLabel,'(e17.10)') self%timeStepMinimum
    call parameters%addParameter('timeStepMinimum'      ,trim(adjustl(parameterLabel)))
    write (parameterLabel,'(i17)   ') self%countTimeStepsMaximum
    call parameters%addParameter('countTimeStepsMaximum',trim(adjustl(parameterLabel)))
    write (parameterLabel,'(i17)   ') self%countOutputBuffer
    call parameters%addParameter('countOutputBuffer'    ,trim(adjustl(parameterLabel)))
    metallicityBoundariesLabel=""
    do i=1,size(self%metallicityTable)
       write (parameterLabel,'(e17.10)') self%metallicityTable(i)
       metallicityBoundariesLabel=metallicityBoundariesLabel//trim(adjustl(parameterLabel))//" "
    end do
    call parameters%addParameter('metallicityBoundaries',char(metallicityBoundariesLabel))
    call self%outputTimes_%descriptor(parameters)
    return
  end subroutine adaptiveDescriptor
