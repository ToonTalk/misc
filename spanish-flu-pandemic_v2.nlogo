;; Generated from http://m.modelling4all.org/m/?frozen=xQ4WXK2O60ae8O5tMva345
;; on Fri Aug 17 11:05:47 UTC 2012

breed [objects object]

turtles-own [
 scheduled-behaviours current-behaviours current-behaviour behaviour-removals rules
 kind dead dirty
 my-daily-flow
 my-infected
 my-next-infected my-next-infected-set
 my-susceptibles
 my-next-susceptibles my-next-susceptibles-set
 my-recovered
 my-next-recovered my-next-recovered-set
 my-dead
 my-next-dead my-next-dead-set
 my-others
 my-next-others my-next-others-set
 my-travel-rate
 my-infection-odds
 my-mortality-odds
 my-encounter-rate
 my-name
 my-nationality
]

patches-own [land-population-of-patch original-population-of-patch medium-distance-travel-destinations-of-patch latitude-of-patch longitude-of-patch  log-patch-attributes]


breed [pens pen]

globals [
the-first-year
the-population-of-usa
the-population-of-britain-norther-france
the-medium-distance-travel-fraction
the-population-movements
the-average-infection-odds
the-average-mortality-odds
the-places
the-pixel-latitude-map
the-first-day
the-global-dead
the-global-dead-previous-day
the-newly-infected
the-newly-recovered
the-previous-index-case
the-previous-history
the-average-duration
the-encounter-rate
the-initial-state
the-army-camps
the-fraction-not-susceptible
the-medium-distance-travel-destinations-count
the-maximum-medium-distance-travel
the-ship-encounter-rate
the-index-cases-camp-funston
the-index-cases-etaples
the-odds-history
the-encounter-rate-changes
the-global-susceptibles
the-global-infected
the-global-recovered
the-previous-view-who
the-default-buttons-should-not-be-added
time cycle-finish-time behind-schedule times-scheduled frame-duration delta-t stop-running
         world-geometry mean-x mean-y mean-z plotting-commands histogram-plotting-commands
         behaviour-procedure-numbers behaviour-names internal-the-other
         button-command radian need-to-clear-drawing
         half-world-width half-world-height negative-half-world-width negative-half-world-height
         observer-commands
         objects-with-something-to-do
         maximum-plot-generations plot-generation
         prototypes total-time no-display-count
         update-patch-attributes-needed
         temp]

to the-model
 initialise-globals
 create-objects 1
  [set kind "World"
   initialise-object
   set hidden? true]
 create-objects 1
  [set kind "Support"
   initialise-object
   set hidden? true]
 create-objects 1
  [set kind "Parameters"
   initialise-object
   set hidden? true]
 create-objects 1
  [set kind "Observer"
   initialise-object
   set hidden? true]
 ask all-of-kind "World"
  [WORLD-MAP-00171
 INITIALISE-00174
 PEACETIME-ADDITIONAL-TRAFFIC-00017
 AUSTRALIAN-RETURN-TRAFFIC-00018
 SCHEDULE-MOVEMENTS-00019
 SET-UP-INDEX-CASE-00180
 SCHEDULE-ODDS-CHANGES-00182
 ARMISTICE-CELEBRATIONS-NORTH-AMERICAN-AND-EUROPE-00027
 ARMISTICE-CELEBRATIONS-AUSTRALIA-AND-NEW-ZEALAND-00028
 SCHEDULE-ENCOUNTER-RATE-CHANGES-00184
 COMPUTE-GLOBAL-INFECTED-00040
 COMPUTE-GLOBAL-SUSCEPTIBLES-00041
 COMPUTE-GLOBAL-RECOVERED-00042
  ]
 ask all-of-kind "Parameters"
  [
  ]
 ask all-of-kind "Observer"
  [
 VIEW-SUB-POPULATION-00072
 MULTIPLE-PLOT-GENERATIONS-00228
 PLOT-SUSCEPTIBLES-00078
 PLOT-INFECTED-00079
 PLOT-RECOVERED-00080
 PLOT-DEATHS-00081
 PLOT-DAILY-DEATHS-00083
 PLOT-DAILY-INFECTED-00084
 PLOT-DAILY-RECOVERED-00085
 SUMMARIZE-OUTCOME-00086
 PAUSE-WHEN-NO-ONE-INFECTED-00087
  ]
end

to-report aef-movements [return-too]
  let us-army-camps
      objects with [is-army-camp? and is-in-continental-usa?]
  let western-europe-places
      objects with [is-stationary? and in-western-europe?]
  let america-odds [[.77  "New York"]
                    [.15  "Newport News"]
                    [.025 "Montreal"]
                    [.025 "Philadelphia"]
                    [.02  "Boston"]
                    [.01  "Quebec City"]]
  let europe-odds [[.435 "Brest"]
                   [.42  "Liverpool"]
                   [.03  "Southampton"]
                   [.03  "London"]
                   [.025 "Glasgow"]
                   [.025 "Bordeaux"]
                   [.025 "Saint-Nazaire"]
                   [.01  "Le Havre"]]
  ; totals in thousands starting June 1917
  let june-1 151 ; days since 1 January
  let monthly-to-europe-totals-1917 [20 18 25 40 45 30 50]
  let monthly-to-europe-totals-1918 [50 50 85 120 245 280 305 295 260 180 30]
  let number-of-camps count us-army-camps
  let first-of-the-month compute-time june-1 1917
  let days-in-month 30.4167
  ; add 0 to the end to 'turn off' the draft
  forEach (sentence monthly-to-europe-totals-1917 monthly-to-europe-totals-1918 0)
    [ ?1 -> if first-of-the-month > 0
       [let daily-flow-per-camp ?1 * 1000 / (days-in-month * number-of-camps)
        do-at-time round first-of-the-month
          [ [] -> ask us-army-camps [set my-daily-flow daily-flow-per-camp] ]]
     set first-of-the-month first-of-the-month + days-in-month ]
  ; totals in thousands starting November 1918
  let monthly-to-america-totals-1918 [35 100]
  let monthly-to-america-totals-1919 [115 180 220 290 335 360]
  let movements []
  let day 0
  if the-first-year < 1918
    [set day june-1
     forEach monthly-to-europe-totals-1917
        [ ?1 -> set movements
             sentence movements
                     (generate-n-movements ?1 round day 1917 america-odds europe-odds us-army-camps)
         set day day + days-in-month ]]
  set day 0
  forEach monthly-to-europe-totals-1918
     [ ?1 -> set movements
          sentence movements
                  (generate-n-movements ?1 round day 1918 america-odds europe-odds us-army-camps)
      set day day + days-in-month ]
  if return-too
    [set day 304 ; 1 November
     forEach monthly-to-america-totals-1918
        [ ?1 -> set movements
             sentence movements
                      (generate-n-movements ?1 round day 1918 europe-odds america-odds western-europe-places)
         set day day + days-in-month ]
     set day 0
     forEach monthly-to-america-totals-1918
        [ ?1 -> set movements
             sentence movements
                      (generate-n-movements ?1 round day 1919 europe-odds america-odds western-europe-places)
         set day day + days-in-month ]]
  report movements
end

to-report generate-n-movements [embarking day year source-odds destination-odds originating-places]
  ; typical 10 day crossing and 8 days to unload and load
  ; maybe 5000 is a typical number of passengers
  let thousands-each-trip 5
  let ship-count round (embarking / thousands-each-trip)
  let ship-frequency 30 / ship-count
  ; conceptually there are lots more trains than boats
  ; but easier to model and less cluttered visualisation
  report n-values ship-count
                  [ ?1 -> generate-round-trip (day + round (?1 * ship-frequency))
                                       year
                                       source-odds
                                       destination-odds
                                       originating-places ]
end

to-report generate-round-trip [day year source-odds destination-odds originating-places]
  let source-port pick-place source-odds
  let destination-port pick-place destination-odds
  report (list (list day year)
               (list (list originating-places 4 1 0 5000 "train")
                     (list source-port 10 8 200 200 "train")
                     (list destination-port 10 8 5000 1000)
                     (list source-port 10 1 200 200 "train")
                     (list originating-places 4 0 500 0 "train"))
               1) ; once since is already a round trip
end

to-report pick-place [odds]
  let x random-float 1.0
  forEach odds
          [ ?1 -> set x x - first ?1
           if x <= 0 [report second ?1] ]
end

to-report compute-color
 if view-who = "Infected"
   [report log-as-hue my-infected]
 if view-who = "Susceptibles"
   [report log-as-hue my-susceptibles]
 if view-who = "Recovered"
   [report log-as-hue my-recovered]
 if view-who = "Dead"
   ; color dead as if the numbers were 10x
   ; since they are typically less than 10%
   [report log-as-hue (my-dead * 10)]
 if view-who = "Others"
   [report log-as-hue my-others]
 report color
end

to-report log-as-hue [sub-population]
 let population total-population
 if sub-population < .5 or population < 1
   [if-else is-transport? or is-army-camp?
      [report green]
      [report [0 0 0 0]]] ; invisible if no sub-population
 let fraction-of-population
     minimum 1 (sub-population / population)
 ; compute hue between 255 and 127
 ;proportional to log of fraction-of-population
 let log-fraction log fraction-of-population 10
 if log-fraction < -6
   [report [0 0 0 0]] ; less than one millionth
 let hue round ((255 * (6 + log-fraction) / 12) + 127.5)
 report __hsb-old hue 255 255
end

to-report transport-size
 ; between 2 and 6 - proportional to population
 report maximum 2
                minimum 6
                        (6 * total-population / 5000)
end

to transfer-from [source amount dead-too]
  if is-agent? source and amount > 0
     [let source-total [next-total-population] of source
      if-else (source-total > 0)
        [if amount > source-total [set amount source-total]
         let fraction amount / source-total
         transfer-from-sub-population source
                                      self
                                      fraction * [my-next-infected] of source
                                      fraction * [my-next-susceptibles] of source
                                      fraction * [my-next-recovered] of source
                                      fraction * [my-next-others] of source
                                      ifelse-value dead-too
                                         [[my-next-dead] of source]
                                         [0]]
        [show (list "No population to transfer from"
                    source "x" pxcor "y" pycor "amount" amount "time" time)]]
end

to transfer-to [destination amount dead-too]
  if is-agent? destination
     [ask destination [transfer-from myself amount dead-too]]
end

to transfer-from-sub-population [source
                                 destination
                                 infected-transferred
                                 susceptibles-transferred
                                 recovered-transferred
                                 others-transferred
                                 dead-transferred]
 ask source
     [set my-next-infected
          my-next-infected - infected-transferred
      set my-next-susceptibles
          my-next-susceptibles - susceptibles-transferred
      set my-next-recovered
          my-next-recovered - recovered-transferred
      set my-next-others
          my-next-others - others-transferred
      set my-next-dead
          my-next-dead - dead-transferred
      set my-next-infected-set true
      set my-next-susceptibles-set true
      set my-next-recovered-set true
      set my-next-others-set true
      set my-next-dead-set true]
 ask destination
     [set my-next-infected
          my-next-infected + infected-transferred
      set my-next-susceptibles
          my-next-susceptibles + susceptibles-transferred
      set my-next-recovered
          my-next-recovered + recovered-transferred
      set my-next-others
          my-next-others + others-transferred
      set my-next-dead
          my-next-dead + dead-transferred
      set my-next-infected-set true
      set my-next-susceptibles-set true
      set my-next-recovered-set true
      set my-next-others-set true
      set my-next-dead-set true]
end

to-report is-quarantined? [population]
  report (is-historical? or is-war-ends-1920?) and
         [is-in-australia?] of population and
         is-fall-1918?
end

to-report is-fall-1918?
 let fall-start compute-time 220 1918
 if time < fall-start [report false]
 if time > fall-start + 120 [report false]
 report true
end

to-report total-population
  report my-susceptibles +
         my-infected +
         my-recovered +
         my-others
end

to-report next-total-population
  report my-next-susceptibles +
         my-next-infected +
         my-next-recovered +
         my-next-others
end

to-report total-land-population-here
  if-else is-agent? land-population-of-patch
    [report [total-population] of land-population-of-patch]
    [report 0]
end

to-report closest-land-population [x y number-moving]
 let this-patch patch x y
 if is-agent? land-population-of-patch
    and [total-population > number-moving] of land-population-of-patch
   [report land-population-of-patch]
 let populated-neighbors
     [neighbors4 with [is-agent? land-population-of-patch and
                       [total-population > number-moving]
                           of land-population-of-patch]]
     of patch x y
 if any? populated-neighbors
    [report [land-population-of-patch]
            of min-one-of populated-neighbors
                          [distancexy x y]]
 report nobody
end

to-report closest-army-camp [x y]
  report min-one-of (objects with [is-army-camp?])
                    [distancexy x y]
end

to-report populations-of-country [name]
  if name = "USA"
     [report the-population-of-usa]
  if name = "Britain and Northern France"
     [report the-population-of-britain-norther-france]
  user-message (word "populations-of-country doesn't yet support " name)
  report no-turtles
end

to travel
  let travelers total-population * my-travel-rate
  let medium-distance-travelers
      travelers * the-medium-distance-travel-fraction
  set travelers travelers - medium-distance-travelers
  let source-population self
  ; travel to neighboring patches
  let destinations
      neighbors4 with [original-population-of-patch > 1]
  if any? destinations and
     (my-infected > .5 or
      any? destinations with [[my-infected] of land-population-of-patch > .5])
    [let destinations-total
         sum [original-population-of-patch] of destinations
     ask destinations
         [ask land-population-of-patch
              [let fraction-of-destinations
                   original-population-of-patch / destinations-total
               let travelers-to-destination
                   travelers * fraction-of-destinations
               if travelers-to-destination >= 1
                 [transfer-from source-population
                                travelers-to-destination
                                false
                  do-after 1
                    [ [] -> transfer-to source-population
                                      travelers-to-destination
                                      false ]]]]]
  ; medium-distance travel to populated patches
  if any? medium-distance-travel-destinations-of-patch and
     (my-infected > .5 or
      any? medium-distance-travel-destinations-of-patch with [[my-infected] of land-population-of-patch > .5])
    [let travelers-to-each-distant-destination
         medium-distance-travelers
         / count medium-distance-travel-destinations-of-patch
     ask medium-distance-travel-destinations-of-patch
        [ask land-population-of-patch
             [transfer-from source-population
                            travelers-to-each-distant-destination
                            false
              do-after 7
                [ [] -> transfer-to source-population
                                  travelers-to-each-distant-destination
                                  false ]]]]
end

to-report population-movements
  let movements the-population-movements
  if is-historical? or is-war-ends-1920?
     [set movements sentence aef-movements is-historical?
                             movements]
  report map
         [ ?1 -> (list ifelse-value is-number? first ?1
                      [first ?1]
                      [compute-time first first ?1
                                    second first ?1]
          (map pre-process-step second ?1)
          ifelse-value (length ?1 > 2)
                [item 2 ?1]
                [1000000]) ]
         movements
end

to-report pre-process-step [step]
  let place place-from-step item 0 step
  let duration item 1 step
  let next-delay
      ifelse-value (length step > 2) [item 2 step] [0]
  let disembark
      ifelse-value (length step > 3) [item 3 step] [0]
  let embark
      ifelse-value (length step > 4) [item 4 step] [0]
  let shape-name
      ifelse-value (length step > 5) [item 5 step] ["boat top"]
  if shape-name = "train"
    ; freight engine looks better than "train" does
    [set shape-name "train freight engine"]
  if shape-name = "boat"
     [set shape-name "boat top"] ; looks better
  report (list place
               duration
               next-delay
               disembark
               embark
               shape-name)
end

to to-camp [nationality number-entering]
  let land-populations
      populations-of-country nationality
  let country-total
      sum [total-population] of land-populations
  let fraction-entering
      number-entering / country-total
  let destination self
  ask land-populations
      [let entering-here
           total-population * fraction-entering
       if entering-here  > .5
         [transfer-to destination entering-here false]]
end

to from-camp [nationality number-leaving]
  let land-populations
      populations-of-country nationality
  let country-total
      sum [total-population] of land-populations
  let fraction-leaving
      number-leaving / country-total
  let source self
  ask land-populations
      [let leaving-from-here
           total-population * fraction-leaving
       if leaving-from-here  > .5
         [transfer-from source leaving-from-here false]]
end

to follow-path [remaining-path original-path repeat-count]
 if-else remaining-path = []
   [if-else repeat-count > 1
      [let reversed-path reverse original-path
       follow-path but-first reversed-path
                   reversed-path
                   repeat-count - 1]
      [set dead true]]
   [let current-step first remaining-path
    let next-place item 0 current-step
    let duration item 1 current-step
    let next-delay item 2 current-step
    let disembarking item 3 current-step
    let embarking item 4 current-step
    set shape item 5 current-step
    set size transport-size
    if is-agentset? next-place
       [let chosen-place max-one-of next-place [total-population]
        set original-path
            replace-places-with-place chosen-place
                                      next-place
                                      original-path
        set next-place chosen-place]
    let distance-to-travel
        ifelse-value is-list? next-place
              [[distancexy item 0 next-place item 1 next-place]
               of patch-here]
              [[distance next-place] of patch-here]
    let delta distance-to-travel / duration
    if-else is-list? next-place
       [facexy item 0 next-place item 1 next-place]
       [face next-place]
    do-after 1
      [ [] -> path-step-movement next-place
                               distance-to-travel
                               delta
                               disembarking
                               embarking
                               next-delay
                               but-first remaining-path
                               original-path
                               repeat-count ]]
end

to path-step-movement [next-place
                       distance-to-travel
                       delta
                       disembarking
                       embarking
                       next-delay
                       remaining-path
                       original-path
                       repeat-count]
 if-else distance-to-travel <= delta
   [if-else is-agent? next-place
     [move-to next-place]
     [setxy item 0 next-place item 1 next-place]
    if-else remaining-path = [] and repeat-count <= 1
      [set dead true]
      [do-after next-delay
          [ [] -> follow-path remaining-path
                            original-path
                            repeat-count ]]
    if disembarking > 0 or embarking > 0
      [if-else is-agent? land-population-of-patch
         [if not is-quarantined? land-population-of-patch
           [transfer-to land-population-of-patch
                        minimum next-total-population
                                disembarking
                        true
            transfer-from land-population-of-patch
                          embarking
                          true]]
         [show (list "no land counter part at "
                     xcor ycor time
                     disembarking embarking
                     remaining-path
                     original-path)]]]
   [forward delta
    do-after 1
        [ [] -> path-step-movement next-place
                                 distance-to-travel - delta
                                 delta
                                 disembarking
                                 embarking
                                 next-delay
                                 remaining-path
                                 original-path
                                 repeat-count ]]
end

to-report replace-places-with-place [chosen-place places path]
  report map [ ?1 -> ifelse-value (first ?1 = places)
                [fput chosen-place butFirst ?1]
                [?1] ]
             path
end

to update-initial-population [population
                              additional-susceptibles
                              additional-others
                              additional-population]
  ask population
      [set my-susceptibles
           my-susceptibles + additional-susceptibles
       set my-others
           my-others + additional-others
       set original-population-of-patch
           original-population-of-patch
           + additional-population]
end

to adjust-infection-and-mortality-odds
  ; assume infection odds is not location dependent
  ask objects [set my-infection-odds the-average-infection-odds]
  ; set the default
  ask objects [set my-mortality-odds the-average-mortality-odds]
  ; based upon ?The Geography and Mortality of the 1918 Influenza Pandemic?
  ; Australia 2.3 vs. 17.6 global average mortality
  ask objects with [is-in-australia?]
      [set my-mortality-odds the-average-mortality-odds * 0.13]
  ; US and Canada is 5.3 vs 17.6
  ask objects with [is-in-us-or-canada?]
      [set my-mortality-odds the-average-mortality-odds * 0.30]
  ; Latin America 9.5 vs 17.6
  ask objects with [is-in-latin-america?]
      [set my-mortality-odds the-average-mortality-odds * 0.54]
  ; Europe 4.8 vs 17.6
  ask objects with [is-in-europe?]
      [set my-mortality-odds the-average-mortality-odds * 0.27]
  ; North Africa 7.5 vs 17.6
  ask objects with [is-in-north-africa?]
      [set my-mortality-odds the-average-mortality-odds * 0.43]
  ; Sub-Sharaha Africa 19.7 vs 17.6
  ask objects with [is-in-sub-sahara-africa?]
      [set my-mortality-odds the-average-mortality-odds * 1.12]
  ; Asia is 27 vs 17.6
  ask objects with [is-in-asia?]
      [set my-mortality-odds the-average-mortality-odds * 1.53]
end

to-report place-from-step [place]
  if is-agent? place or is-agentset? place
     [report place]
  if is-list? place
     [report (list longitude-to-x item 1 place
                   latitude-to-y item 0 place)]
  if is-string? place
     [forEach the-places
              [ ?1 -> if first ?1 = place
                 [report (list longitude-to-x item 2 ?1
                               latitude-to-y item 1 ?1)] ]]
  show (list "Could not find" place "in" the-places time)
  report [0 0]
end

to-report longitude-to-x [longitude]
  ; Grenwich is exactly in the middle
  report ((longitude + 180) * world-width) / 360
end

to-report latitude-to-y [latitude]
  ; just interpolates between a dozen or so samples
  ; (using Google Earth and the original map)
  let lower-latitude -91
  let lower-y 0
  forEach the-pixel-latitude-map
          [ ?1 -> let next-y first ?1
           let next-latitude item 1 ?1
           if-else (latitude > next-latitude)
                   [set lower-latitude next-latitude
                    set lower-y next-y]
                   [if lower-latitude >= -90
                       [let gap-latitude
                            next-latitude - lower-latitude
                        let gap-y next-y - lower-y
                        let gap-fraction
                            (latitude - lower-latitude)
                            / gap-latitude
                        report lower-y
                               + gap-fraction * gap-y]] ]
  report max-pycor
end

to-report x-to-longitude [x]
  ; Grenwich is exactly in the middle of 816/8 pixels
  report ((x * 360) / world-width) - 180
end

to-report y-to-latitude [y]
  ; just interpolates between a dozen or so samples
  ; (using Google Earth and the original map)
  let lower-latitude 0
  let lower-y -1
  forEach the-pixel-latitude-map
          [ ?1 -> let next-y first ?1
           let next-latitude item 1 ?1
           if-else y > next-y
             [set lower-latitude next-latitude
              set lower-y next-y]
             [if lower-y >= 0
                [let gap-latitude
                     next-latitude - lower-latitude
                 let gap-y next-y - lower-y
                 let gap-fraction
                     (y - lower-y) / gap-y
                 report lower-latitude
                        + gap-fraction * gap-latitude]] ]
  report -55.5 ; if y is 0
end

to-report location-description [x y]
  let latitude-1 round y-to-latitude y
  let latitude-2 round y-to-latitude (y + 1)
  let longitude-1 round x-to-longitude x
  let longitude-2 round x-to-longitude (x + 1)
  report (word abs latitude-1 " "
               north-south latitude-1 " to "
               abs latitude-2 " "
               north-south latitude-2 "; "
               abs longitude-1 " "
               east-west longitude-1 " to "
               abs longitude-2 " "
               east-west longitude-2)
end

to-report north-south [latitude]
  if-else latitude >= 0 [report "N"] [report "S"]
end

to-report east-west [longitude]
  if-else longitude >= 0 [report "W"] [report "E"]
end

to-report is-transport?
  report shape = "boat top" or
         shape = "train freight engine"
end

to-report is-stationary?
  report shape = "square"
end

to-report is-in-australia?
 ; NW: -9.449062,142,111.344239
 ; SE: -43.771094,155.729004
 report latitude-of-patch <= -9.45 and
        latitude-of-patch >= -43.77 and
        longitude-of-patch >= 111.34 and
        longitude-of-patch <= 155.73
end

to-report is-in-us-or-canada?
 ; NW: 83.068774,-173.373045
 ; SE: 27.371767,-52.083982
 report latitude-of-patch <= 83 and
        latitude-of-patch >= 27.37 and
        longitude-of-patch >= -173 and
        longitude-of-patch <= -52
end

to-report is-in-continental-usa?
 ; NW: 49,-173.373045
 ; SE: 27.371767,-52.083982
 report latitude-of-patch <= 49 and
        latitude-of-patch >= 27.37 and
        longitude-of-patch >= -173 and
        longitude-of-patch <= -52
end

to-report is-in-latin-america?
 ; NW: 27.371767,-121.693357
 ; SE: -55.973798,-33.099607
 report latitude-of-patch <= 27.36 and
        latitude-of-patch >= -56 and
        longitude-of-patch >= -122 and
        longitude-of-patch <= -33
end

to-report is-in-sub-sahara-africa?
 ; includes Suhara
 ; NW: 25.799891,-17.780272
 ; SE: -34.741612,52.004884
 report latitude-of-patch <= 26 and
        latitude-of-patch >= -35 and
        longitude-of-patch >= -18 and
        longitude-of-patch <= 52
end

to-report is-in-north-africa?
 ; NW: 37.46067,-27.123045
 ; SE: 25.799891,51.626955
 report latitude-of-patch <= 37.46 and
        latitude-of-patch >= 25.99 and
        longitude-of-patch >= -27 and
        longitude-of-patch <= 52
end

to-report is-in-africa?
  report is-in-sub-sahara-africa? or is-in-north-africa?
end

to-report is-in-europe?
 ; NW: 71.469124,-20.065429
 ; SE: 37.603719,32.493165
 report latitude-of-patch <= 71 and
        latitude-of-patch >= 37.45 and
        longitude-of-patch >= -20 and
        longitude-of-patch <= 32
end

to-report in-western-europe?
 ; NW: 71.469124,-20.065429
 ; SE: 39.504041,11.575196
 report latitude-of-patch <= 71 and
        latitude-of-patch >= 37.45 and
        longitude-of-patch >= -20 and
        longitude-of-patch <= 12
end

to-report is-in-britain?
 ; NW: 58.83649,-6.730224
 ; SE: 50.792047,1.355713
 ; due to round off problems the above didn't work
 report latitude-of-patch <= 68.8 and
        latitude-of-patch >= 44 and
        longitude-of-patch >= -6.7 and
        longitude-of-patch <= -0.5
end

to-report is-in-northern-france?
 ; area occupied by British troops
 ; NW: 51.103522,1.487824
 ; SE: 49.884017,2.976471
 report latitude-of-patch <= 51.1 and
        latitude-of-patch >= 49.9 and
        longitude-of-patch >= 1.5 and
        longitude-of-patch <= 3
end

to-report is-in-asia?
 ; NW: 77.078784,32.493165
 ; SE: -9.795678,-173.373045
 report (latitude-of-patch <= 77 and
         latitude-of-patch >= -10 and
         longitude-of-patch >= 32 or
         longitude-of-patch <= -173) and
        not is-in-africa?
end

to-report is-army-camp?
 report kind = "Army camp"
end

to-report is-historical?
 report history = "Historical"
end

to-report is-no-war?
 report history = "No war"
end

to-report is-war-ends-1920?
 report history = "War ends 1920"
end

to-report patch-under-mouse-description
 if-else mouse-inside?
  [let area patch floor mouse-xcor floor mouse-ycor
   ; watch area
   let populations [objects-here] of area
   if-else any? populations
      [let total sum [total-population] of populations
       report (word "total=" to-word round total 7
                    "; infected = "
                    percent round sum [my-infected] of populations total 5
                    "; susceptibles = "
                    percent round sum [my-susceptibles] of populations total 1
                    "; recovered = "
                    percent round sum [my-recovered] of populations total 1
                    "; dead = "
                    percent round sum [my-dead] of populations total 5
  ;                  "; others = "
  ;                  percent round sum [my-others] of populations total 1
                    " at " location-description floor mouse-xcor floor mouse-ycor)
      ]
      [report "Zero population"]]
   [reset-perspective
    if-else times-scheduled = 0
      [report "Click GO to start the simulation"]
      [if-else time <= 1.0E-6
         [report "Loading, please wait."]
         [report "Move mouse over an area to display population statistics. Move off map to restore display."]]]
end

to-report percent [sub-population total accuracy]
  let percentage sub-population * 100 / total
  let percentage-plus-100 precision (100 + percentage) accuracy
  if percentage-plus-100 = 200
    [report (word (repeat-word " " maximum 0 (accuracy - 4)) "100%")]
  let percentage-word but-first (word percentage-plus-100 "%")
  if-else percentage < 10
    [report (word " " but-first percentage-word)]
    [report percentage-word]
end

to-report to-word [n len]
  let number-of-spaces ifelse-value (n < 10) [len - 1] [floor (len - log n 10)]
  report (word (repeat-word " " number-of-spaces) n)
end

to-report repeat-word [w n]
  if-else n <= 1
    [report w]
    [report (word w (repeat-word w (n - 1)))]
end

to-report compute-date
 if the-first-year = 0 [report ""]
 let days-since-jan-1 floor time + the-first-day
 let day days-since-jan-1 mod 365 + 1
 let month "Jan"
 let year the-first-year + floor (days-since-jan-1 / 365)
 report date day year
end

to-report date [day year]
 if day > 334 [report date-string (day - 334) "Dec" year]
 if day > 304 [report date-string (day - 304) "Nov" year]
 if day > 273 [report date-string (day - 273) "Oct" year]
 if day > 243 [report date-string (day - 243) "Sep" year]
 if day > 212 [report date-string (day - 212) "Aug" year]
 if day > 181 [report date-string (day - 181) "Jul" year]
 if day > 151 [report date-string (day - 151) "Jun" year]
 if day > 120 [report date-string (day - 120) "May" year]
 if day >  90 [report date-string (day -  90) "Apr" year]
 if day >  59 [report date-string (day -  59) "Mar" year]
 if day >  31 [report date-string (day -  31) "Feb" year]
 report date-string day "Jan" year
end

to-report date-string [day month year]
  report (word ifelse-value (day < 10) [(word " " day)] [day] " "
               month " "
               year)
end

to-report compute-time [day year]
 let days day - the-first-day
 let years year - the-first-year
 report days + years * 365
end

to-report daily-deaths
  let new-deaths the-global-dead - the-global-dead-previous-day
  set the-global-dead-previous-day the-global-dead
  report new-deaths
end

to-report daily-infected
  let new-infected the-newly-infected
  set the-newly-infected 0
  report new-infected
end

to-report daily-recovered
  let new-recovered the-newly-recovered
  set the-newly-recovered 0
  report new-recovered
end

to-report darken-by-generation [c]
 let hue-staturation-brightness __extract-hsb-old c
 report __approximate-hsb-old
        item 0 hue-staturation-brightness
        item 1 hue-staturation-brightness
        (maximum 0 ((item 2 hue-staturation-brightness) - (plot-generation * 40)))
end

to-report lighten-by-generation [c]
 let hue-staturation-brightness __extract-hsb-old c
 report __approximate-hsb-old
        item 0 hue-staturation-brightness
        item 1 hue-staturation-brightness
        (minimum 255 ((item 2 hue-staturation-brightness) + (plot-generation * 40)))
end

to reset
  set the-first-year 0
  setup
end
; this is a reporter rather than a command
; to workaround a NetLogo problem with
; (reset-or-resume go) on the Go button.

to-report reset-or-resume
  if the-previous-index-case != index-case and
     not uninitialised? index-case
    [clear-patches
     clear-drawing
     clear-turtles
     clear-plot
     setup]
  if the-previous-history != history and
     not uninitialised? history
    [setup]
  if is-no-war? and index-case = "Etaples" and
    (the-previous-history != history or the-previous-index-case != index-case)
    [output-print "It is unlikely that Etaples would have been the origin of the influenza with no war. There would not have been a military base there."]
      set the-previous-history history
  set the-previous-history history
  set the-previous-index-case index-case
  report true ; ok to go
end

to TRANSMIT-00001
do-every (1)
  [ [] -> if (my-infected > .5)
 [
let fraction-not-infected
1 - (my-infected / total-population)
let odds-of-encountering-infected
1 - fraction-not-infected ^ my-encounter-rate
let newly-infected
my-susceptibles *
odds-of-encountering-infected *
my-infection-odds
set my-next-infected-set true
 set my-next-infected
my-next-infected + newly-infected
set my-next-susceptibles-set true
 set my-next-susceptibles
my-next-susceptibles - newly-infected
set the-newly-infected
the-newly-infected + newly-infected
] ]
end

to RECOVER-00002
do-every (1)
  [ [] -> if (my-infected > 0)
 [
let recovered my-infected / the-average-duration
set my-next-recovered-set true
 set my-next-recovered my-next-recovered + recovered
set my-next-infected-set true
 set my-next-infected my-next-infected - recovered
set the-newly-recovered the-newly-recovered + recovered
] ]
end

to MORTALITY-00003
do-every (1)
  [ [] ->
let deceased my-infected * my-mortality-odds
/ the-average-duration
set my-next-infected-set true
 set my-next-infected my-next-infected - deceased
set my-next-dead-set true
 set my-next-dead my-next-dead + deceased
set the-global-dead the-global-dead + deceased ]
end

to SECOND-WAVE-00004
do-after (random-integer-between 1 21)
  [ [] -> do-after (compute-time 230 1918)
  [ [] ->
let fraction-becomes-susceptible
random-number-between .06 .65
let newly-susceptible
my-recovered * fraction-becomes-susceptible
set my-next-susceptibles-set true
 set my-next-susceptibles
my-next-susceptibles + newly-susceptible
set my-next-recovered-set true
 set my-next-recovered
my-next-recovered - newly-susceptible ] ]
end

to THIRD-WAVE-00005
do-after (random-integer-between 1 21)
  [ [] -> do-after (compute-time 15 1919)
  [ [] ->
let fraction-becomes-susceptible
random-number-between .91 .97
let newly-susceptible
my-recovered * fraction-becomes-susceptible
set my-next-susceptibles-set true
 set my-next-susceptibles
my-next-susceptibles + newly-susceptible
set my-next-recovered-set true
 set my-next-recovered
my-next-recovered - newly-susceptible ] ]
end

to ENCOUNTER-RATE-00167
set my-encounter-rate
3 * the-encounter-rate
end

to TRAVEL-RATE-00168
set my-travel-rate
.01
end

to POSSIBLE-SHAPES-00169
set shape "boat top"
set shape "train freight engine"
set shape "square"
end

to SIZE-00170
set size 1.25
end

to UPDATE-COLOR-00010
do-every (1)
  [ [] ->
set
color compute-color ]
end

to WORLD-MAP-00171
run-in-observer-context
[ [] -> import-drawing "world.png" ]
end

to INITIALISE-00174
let just-created-agents nobody
let longitude-of-a-patch world-width / 360
forEach the-initial-state
   [ ?1 -> let longitude item 0 ?1
    let latitude item 1 ?1
    let x longitude-to-x longitude
    let y round latitude-to-y latitude
    let population item 2 ?1
    let others the-fraction-not-susceptible * population
    let susceptibles population - others
    ; to deal with round off errors that could leave regions
    ; unpopulated we share the population with the neighbours
    let x1 floor x
    let x2 x1 + 1 ; patch to east
    let patch1 patch x1 y
    let patch2 patch x2 y
    let patch2-share x - x1
    let patch1-share 1 - patch2-share
    let patch1-susceptibles susceptibles * patch1-share
    let patch2-susceptibles susceptibles * patch2-share
    let patch1-others others * patch1-share
    let patch2-others others * patch2-share
    let patch1-population population * patch1-share
    let patch2-population population * patch2-share
    ; duplicating code below since added NetLogo primitives
    ; don't process create-objects (yet)
    let patch1-land-population
        [one-of objects-here
                 with [not dead and
                       kind = "Population" and
                       is-stationary?]] of patch1
    if-else is-agent? patch1-land-population
       [update-initial-population patch1-land-population
                                  patch1-susceptibles
                                  patch1-others
                                  patch1-population]
       [set just-created-agents nobody
ask patch-here [sprout-objects 1 [
 set just-created-agents (turtle-set self just-created-agents)
 set kind "Population"
          ]]
ask just-created-agents [
 set xcor xcor
 set ycor ycor
 initialise-object
 initialise-previous-state
 TRANSMIT-00001
 RECOVER-00002
 MORTALITY-00003
 SECOND-WAVE-00004
 THIRD-WAVE-00005
 ENCOUNTER-RATE-00167
 TRAVEL-RATE-00168
 POSSIBLE-SHAPES-00169
 SIZE-00170
 UPDATE-COLOR-00010
 set my-susceptibles patch1-susceptibles
           set my-others patch1-others
           setxy x1 y
           ; transports don't do this so not in prototype
           do-every 1  "travel"
 ]
        ask patch1
            [set longitude-of-patch longitude
             set latitude-of-patch latitude
             set original-population-of-patch
                 patch1-population]]
    let patch2-land-population
        [one-of objects-here
                 with [not dead and
                       kind = "Population" and
                       is-stationary?]] of patch2
    if-else is-agent? patch2-land-population
       [update-initial-population patch2-land-population
                                  patch2-susceptibles
                                  patch2-others
                                  patch2-population]
       [set just-created-agents nobody
ask patch-here [sprout-objects 1 [
 set just-created-agents (turtle-set self just-created-agents)
 set kind "Population"
          ]]
ask just-created-agents [
 set xcor xcor
 set ycor ycor
 initialise-object
 initialise-previous-state
 TRANSMIT-00001
 RECOVER-00002
 MORTALITY-00003
 SECOND-WAVE-00004
 THIRD-WAVE-00005
 ENCOUNTER-RATE-00167
 TRAVEL-RATE-00168
 POSSIBLE-SHAPES-00169
 SIZE-00170
 UPDATE-COLOR-00010
 set my-susceptibles patch2-susceptibles
           set my-others patch2-others
           setxy x2 y
           do-every 1  "travel"
 ]
        ask patch2
            [set longitude-of-patch
                 longitude + longitude-of-a-patch
            set latitude-of-patch latitude
            set original-population-of-patch
                patch2-population]] ]
ask objects with [kind = "Population" and total-population < 1]
    [set dead true]
set the-population-of-usa
    objects with [is-stationary? and
                  is-in-continental-usa?]
set the-population-of-britain-norther-france
    objects with [is-stationary? and
                  (is-in-britain? or is-in-northern-france?)]
ask patches with [true] [set medium-distance-travel-destinations-of-patch
         (max-n-of the-medium-distance-travel-destinations-count
                  other patches in-radius
                                the-maximum-medium-distance-travel
                 [original-population-of-patch])
         with [original-population-of-patch > 0]
     set land-population-of-patch
         one-of objects-here
                 with [not dead and
                       kind = "Population" and
                       is-stationary?]]
if (is-historical? or is-war-ends-1920?) and
   not uninitialised? the-army-camps
  [forEach the-army-camps
      [ ?1 -> let nationality-of-troops item 0 ?1
       forEach item 1 ?1
          [ ??1 -> let name item 0 ??1
           let latitude item 1 ??1
           let longitude item 2 ??1
           let population item 3 ??1
           let daily-flow item 4 ??1
           let x longitude-to-x longitude
           let y latitude-to-y latitude
           set just-created-agents nobody
ask patch-here [sprout-objects 1 [
 set just-created-agents (turtle-set self just-created-agents)
 set kind "Army camp"
              ]]
ask just-created-agents [
 set xcor xcor
 set ycor ycor
 initialise-object
 initialise-previous-state
 TRANSMIT-00001
 RECOVER-00002
 MORTALITY-00003
 SECOND-WAVE-00004
 THIRD-WAVE-00005
 ENCOUNTER-RATE-00167
 TRAVEL-RATE-00168
 POSSIBLE-SHAPES-00169
 SIZE-00170
 UPDATE-COLOR-00010
 INTO-CAMP-00092
 CLOSE-CAMP-00093
 ENCOUNTER-RATE-00234
 SHAPE-00235
 SIZE-00236
 set my-name name
               set my-nationality nationality-of-troops
               set my-daily-flow daily-flow
               setxy x y
               ; delay the draft until other initialisation
               ; completed
               do-after .1
                  [ [] -> to-camp nationality-of-troops
population ]
               ; American troops go from camps to ships
               ; to Europe and return after the war
               ; Others flow in and out within their territory.
               if nationality-of-troops != "USA"
                 [do-after 1
                     [ [] -> do-every 1
                        [ [] -> from-camp nationality-of-troops
my-daily-flow ] ]]
               do-every 1  "travel"
 ] ] ]]
end

to PEACETIME-ADDITIONAL-TRAFFIC-00017
if (is-no-war?)
 [
set
the-population-movements
sentence the-population-movements
[[1 [["Philadelphia" 7 4 3000 3000]
["London" 7 4 3000 3000]]]
[3 [["Glasgow" 7 4 3000 3000]
["Boston" 7 4 3000 3000]]]
[5 [["Baltimore" 7 4 3000 3000]
["Bordeaux" 7 4 3000 3000]]]
[7 [["Marseilles" 7 4 3000 3000]
["Montreal" 7 4 3000 3000]]]
[2 [["Glasgow" 10 3 3000 3000]["Panama Canal" 14 3 100 100]
["Auckland" 2 3 1000 1000]["Melbourne" 4 3 3000 3000]]]
[5 [["Sydney" 4 3 3000 3000]["Auckland" 14 3 100 100]
["Panama Canal" 10 3 1000 1000]["Southampton" 2 3 3000 3000]]]
[8 [["London" 10 3 3000 3000]["Panama Canal" 14 3 100 100]
["Auckland" 2 3 1000 1000]["Sydney" 4 3 3000 3000]]]
[15 [["Melbourne" 4 3 3000 3000]["Auckland" 14 3 100 100]
["Panama Canal" 10 3 1000 1000]["Liverpool" 2 3 3000 3000]]]
[3 [["London" 3 8 3000 3000]["Lisbon" 2 2 100 100]
[[25 -22]2 0 0 0]["Dakar" 4 2 100 100]
["Cape Town" 4 2 500 500]
["Calcutta" 8 3 3000 3000]]]
[19 [["Bristol" 3 8 3000 3000]["Lisbon" 2 2 100 100]
[[25 -22]2 0 0 0]["Dakar" 4 2 100 100]
["Cape Town" 4 2 500 500]
["Bombay" 8 3 3000 3000]]]
[11 [["San Francisco" 7 3 3000 3000]["Honolulu" 7 3 1000 1000]
["Tokyo" 4 3 1000 1000]
["Shanghai" 14 3 3000 3000]]]
[20 [["Shanghai" 4 3 3000 3000]["Tokyo" 7 3 1000 1000]
["Honolulu" 7 3 1000 1000]
["Seattle" 14 3 3000 3000]]]
]
]
end

to AUSTRALIAN-RETURN-TRAFFIC-00018
if (history = "Historical")
 [
set
the-population-movements
sentence the-population-movements
[[[345 1918][["Brest" 10 3 10000 10000][[25 -22]2 0 0 0]["Dakar" 4 1 100 100]
["Cape Town" 4 1 100 100]
[[-42 147]9 0 0 0]
["Sydney" 3 3 5000 5000]] 4]
[[355 1918][["Le Havre" 10 3 10000 10000][[25 -22]2 0 0 0]["Dakar" 4 1 100 100]
["Cape Town" 4 1 100 100]
["Melbourne" 12 3 5000 5000]] 4]
[[1 1919][["Brest" 10 3 10000 10000][[25 -22]2 0 0 0]["Dakar" 4 1 100 100]
["Cape Town" 4 1 100 100]
[[-42 147]9 0 0 0]
["Sydney" 3 3 5000 5000]] 4]
[[10 1919][["Le Havre" 10 3 10000 10000][[25 -22]2 0 0 0]["Dakar" 4 1 100 100]
["Cape Town" 4 1 100 100]
["Melbourne" 12 3 5000 5000]] 4]
[[25 1919][["Brest" 10 3 10000 10000][[25 -22]2 0 0 0]["Dakar" 4 1 100 100]
["Cape Town" 4 1 100 100]
[[-42 147]9 0 0 0]
["Sydney" 3 3 5000 5000]] 4]
[[40 1919][["Le Havre" 10 3 10000 10000][[25 -22]2 0 0 0]["Dakar" 4 1 100 100]
["Cape Town" 4 1 100 100]
["Melbourne" 12 3 5000 5000]] 4]
[[55 1919][["Brest" 10 3 10000 10000][[25 -22]2 0 0 0]["Dakar" 4 1 100 100]
["Cape Town" 4 1 100 100]
[[-42 147]9 0 0 0]
["Sydney" 3 3 5000 5000]] 4]
[[70 1919][["Le Havre" 10 3 10000 10000][[25 -22]2 0 0 0]["Dakar" 4 1 100 100]
["Cape Town" 4 1 100 100]
["Melbourne" 12 3 5000 5000]] 4]
[[80 1919][["Brest" 10 3 10000 10000][[25 -22]2 0 0 0]["Dakar" 4 1 100 100]
["Cape Town" 4 1 100 100]
[[-42 147]9 0 0 0]
["Sydney" 3 3 5000 5000]] 4]
[[90 1919][["Le Havre" 10 3 10000 10000][[25 -22]2 0 0 0]["Dakar" 4 1 100 100]
["Cape Town" 4 1 100 100]
["Melbourne" 12 3 5000 5000]] 4]
]
]
end

to SCHEDULE-MOVEMENTS-00019
let just-created-agents nobody
do-after (1)
  [ [] ->
forEach population-movements
   [ ??1 -> let start-time item 0 ??1
    if is-list? start-time
       [set start-time
            compute-time first start-time second start-time]
    let path item 1 ??1
    let repeat-count item 2 ??1
    let initial-step item 0 path
    let from-place item 0 initial-step
    let number-moving item 4 initial-step
    let from-population
        ifelse-value is-list? from-place
           [closest-land-population item 0 from-place
                                    item 1 from-place
                                    number-moving]
           [from-place]
    let shape-name item 5 initial-step
    if-else is-agent? from-population or
            is-agentset? from-population
       [if start-time >= 0
          [do-at-time start-time
              [ [] -> if is-agentset? from-population
               [set from-population
                    max-one-of from-population [total-population]]
              ask from-population
                  [let total total-population
                    if-else total >= number-moving
                      [let fraction number-moving / total
                       let susceptibles-moving
                           fraction * my-next-susceptibles
                       set my-next-susceptibles
                           my-next-susceptibles - susceptibles-moving
                       let infected-moving
                           fraction * my-next-infected
                       set my-next-infected
                           my-next-infected - infected-moving
                       let recovered-moving
                           fraction * my-next-recovered
                       set my-next-recovered
                           my-next-recovered - recovered-moving
                       let others-moving
                           fraction * my-next-others
                       set my-next-others
                           my-next-others - others-moving
                       ; hard to stay isolated on a ship
                       ; so reduce others by half
                       set susceptibles-moving
                           susceptibles-moving + my-next-others / 2
                       set my-next-others my-next-others / 2
                       set just-created-agents nobody
ask patch-here [sprout-objects 1 [
 set just-created-agents (turtle-set self just-created-agents)
 set kind "Population"
                          ]]
ask just-created-agents [
 set xcor xcor
 set ycor ycor
 initialise-object
 initialise-previous-state
 TRANSMIT-00001
 RECOVER-00002
 MORTALITY-00003
 SECOND-WAVE-00004
 THIRD-WAVE-00005
 ENCOUNTER-RATE-00167
 TRAVEL-RATE-00168
 POSSIBLE-SHAPES-00169
 SIZE-00170
 UPDATE-COLOR-00010
 set my-susceptibles susceptibles-moving
set my-infected infected-moving
set my-recovered recovered-moving
set my-others others-moving
set my-encounter-rate
the-ship-encounter-rate
set shape shape-name
set size transport-size
set color green
if-else is-list? from-place
[setxy item 0 from-place
item 1 from-place]
[move-to from-population]
follow-path
but-first path
path
repeat-count
 ]]
[show (list "Scheduled impossible movement"
"number-moving" number-moving
"total-here" total
from-population from-place shape time)]] ]]]
[show (list "no population at scheduled movement"
from-place time shape ??1)] ] ]
end

to SET-UP-INDEX-CASE-00180
let index-case-data []
if-else index-case = "Funston"
[set index-case-data the-index-cases-camp-funston]
[set index-case-data the-index-cases-etaples]
forEach
index-case-data
[ ?1 -> let day item 0 ?1
let year item 1 ?1
let longitude item 2 ?1
let latitude item 3 ?1
let number-infected item 4 ?1
let x longitude-to-x longitude
let y latitude-to-y latitude
let population closest-army-camp x y
if not is-agent? population
; if running with 'No war' then there are no camps
[set population
closest-land-population x y number-infected]
if-else
is-agent? population
[ask population [set my-infected number-infected]
if
uninitialised? the-first-day
[set the-first-day day]
if
uninitialised? the-first-year
[set the-first-year year
let maximum-day (1920 - year) * 365 - day
set-current-plot "Populations"
set-plot-x-range 0 maximum-day
set-current-plot "Daily Population Change"
set-plot-x-range 0 maximum-day]]
[show (list "No population for index case" ?1 x y)] ]
end

to SCHEDULE-ODDS-CHANGES-00182
forEach the-odds-history
   [ ?1 -> let day item 0 ?1
    let year item 1 ?1
    let infection-odds item 2 ?1
    let mortality-odds item 3 ?1
    do-at-time (compute-time day year)
        [ [] -> set the-average-infection-odds infection-odds
set the-average-mortality-odds mortality-odds
adjust-infection-and-mortality-odds ] ]
end

to ARMISTICE-CELEBRATIONS-NORTH-AMERICAN-AND-EUROPE-00027
if (is-historical?)
 [
set
the-encounter-rate-changes
sentence the-encounter-rate-changes
[[314 1918 10 -166 46 27 76]
[315 1918 2.5 -166 46 27 76]
[316 1918 2 -166 46 27 76]
[317 1918 2 -166 46 27 76]]
]
end

to ARMISTICE-CELEBRATIONS-AUSTRALIA-AND-NEW-ZEALAND-00028
if (is-historical?)
 [
set
the-encounter-rate-changes
sentence the-encounter-rate-changes
[[314 1918 10 -9 142 -48 -174]
[315 1918 2.5 -9 142 -48 -174]
[316 1918 2 -9 142 -48 -174]
[317 1918 2 -9 142 -48 -174]]
]
end

to SCHEDULE-ENCOUNTER-RATE-CHANGES-00184
forEach the-encounter-rate-changes
   [ ?1 -> let day item 0 ?1
    let year item 1 ?1
    let factor item 2 ?1
    let min-x longitude-to-x item 3 ?1
    let max-x longitude-to-x item 4 ?1
    let min-y latitude-to-y item 5 ?1
    let max-y latitude-to-y item 6 ?1
    let new-encounter-rate
        factor * the-encounter-rate
    let populations
        objects with [kind = "Population"]
    let time-of-change
        compute-time day year
    do-at-time time-of-change
        [ [] -> ask populations
with [xcor >= min-x and
xcor <= max-x and
ycor >= min-y and
ycor <= max-y]
[set my-encounter-rate
new-encounter-rate] ]
    do-at-time (time-of-change + 1)
        [ [] -> ask populations
[set my-encounter-rate
the-encounter-rate] ] ]
end

to COMPUTE-GLOBAL-INFECTED-00040
do-every (1)
  [ [] ->
set
the-global-infected
maximum sum [round my-infected]of objects 0 ]
end

to COMPUTE-GLOBAL-SUSCEPTIBLES-00041
do-every (1)
  [ [] ->
set
the-global-susceptibles
maximum sum [round my-susceptibles]of objects 0 ]
end

to COMPUTE-GLOBAL-RECOVERED-00042
do-every (1)
  [ [] ->
set
the-global-recovered
maximum sum [round my-recovered]of objects 0 ]
end

to VIEW-SUB-POPULATION-00072
do-every (1)
  [ [] ->
if
view-who != the-previous-view-who
[ask all-of-kind "Population"
[set color compute-color]
set
the-previous-view-who view-who] ]
end

to MULTIPLE-PLOT-GENERATIONS-00228
set maximum-plot-generations 10000
end

to PLOT-SUSCEPTIBLES-00078
do-at-time (1)
  [ [] -> do-every (1)
  [ [] ->
set-current-plot
"Populations"
create-temporary-plot-pen "Susceptible"
; this name will be used in the legend if enabled
set-plot-pen-color darken-by-generation blue
set-plot-pen-mode 0
; 0 for line, 1 for bar, 2 for point
; plot-pen-reset ; remove the ';' in the box to erase everything drawn by this pen
add-to-plot time
log (.1 + the-global-susceptibles) 10 ] ]
end

to PLOT-INFECTED-00079
do-at-time (1)
  [ [] -> do-every (1)
  [ [] ->
set-current-plot
"Populations"
create-temporary-plot-pen "Infected"
; this name will be used in the legend if enabled
set-plot-pen-color darken-by-generation red
set-plot-pen-mode 0
; 0 for line, 1 for bar, 2 for point
; plot-pen-reset ; remove the ';' in the box to erase everything drawn by this pen
add-to-plot time
log (.1 + the-global-infected) 10 ] ]
end

to PLOT-RECOVERED-00080
do-at-time (1)
  [ [] -> do-every (1)
  [ [] ->
set-current-plot
"Populations"
create-temporary-plot-pen "Recovered"
; this name will be used in the legend if enabled
set-plot-pen-color darken-by-generation green
set-plot-pen-mode 0
; 0 for line, 1 for bar, 2 for point
; plot-pen-reset ; remove the ';' in the box to erase everything drawn by this pen
add-to-plot time
log (.1 + the-global-recovered) 10 ] ]
end

to PLOT-DEATHS-00081
do-at-time (1)
  [ [] -> do-every (1)
  [ [] ->
set-current-plot
"Populations"
create-temporary-plot-pen "Deaths"
; this name will be used in the legend if enabled
set-plot-pen-color darken-by-generation gray
set-plot-pen-mode 0
; 0 for line, 1 for bar, 2 for point
; plot-pen-reset ; remove the ';' in the box to erase everything drawn by this pen
add-to-plot time
log (.1 + the-global-dead) 10 ] ]
end

to PLOT-DAILY-DEATHS-00083
do-at-time (.000001)
  [ [] -> do-every (1)
  [ [] ->
set-current-plot
"Daily Population Change"
create-temporary-plot-pen "Deaths"
; this name will be used in the legend if enabled
set-plot-pen-color darken-by-generation gray
set-plot-pen-mode 0
; 0 for line, 1 for bar, 2 for point
; plot-pen-reset ; remove the ';' in the box to erase everything drawn by this pen
add-to-plot time
log (maximum .1 daily-deaths) 10 ] ]
end

to PLOT-DAILY-INFECTED-00084
do-at-time (.000001)
  [ [] -> do-every (1)
  [ [] ->
set-current-plot
"Daily Population Change"
create-temporary-plot-pen "Infected"
; this name will be used in the legend if enabled
set-plot-pen-color darken-by-generation red
set-plot-pen-mode 0
; 0 for line, 1 for bar, 2 for point
; plot-pen-reset ; remove the ';' in the box to erase everything drawn by this pen
add-to-plot time
log (maximum .1 daily-infected) 10 ] ]
end

to PLOT-DAILY-RECOVERED-00085
do-at-time (.000001)
  [ [] -> do-every (1)
  [ [] ->
set-current-plot
"Daily Population Change"
create-temporary-plot-pen "Recovered"
; this name will be used in the legend if enabled
set-plot-pen-color darken-by-generation green
set-plot-pen-mode 0
; 0 for line, 1 for bar, 2 for point
; plot-pen-reset ; remove the ';' in the box to erase everything drawn by this pen
add-to-plot time
log (maximum .1 daily-recovered) 10 ] ]
end

to SUMMARIZE-OUTCOME-00086
when  [ [] -> the-global-infected < 1 and time > 1 ]
 [ [] ->

output-print
(word "Total number of deaths due to the pandemic were "
round the-global-dead
" where history = '"
history
"'and index case = '" index-case
"'.") ]
end

to PAUSE-WHEN-NO-ONE-INFECTED-00087
when  [ [] -> the-global-infected < 1 and time > 1 ]
 [ [] ->
set stop-running true ]
end

to INTO-CAMP-00092
do-at-time (1)
  [ [] -> do-every (1)
  [ [] ->

to-camp
my-nationality
my-daily-flow ] ]
end

to CLOSE-CAMP-00093
if (is-historical?)
 [do-at-time ((compute-time 314 1918)
 +
(random-integer-between 7 30))
  [ [] ->
set
my-daily-flow 0
set my-encounter-rate the-encounter-rate
from-camp my-nationality

total-population * .9 ]
]
end

to ENCOUNTER-RATE-00234
set my-encounter-rate
3 * the-encounter-rate
end

to SHAPE-00235
set shape "star"
end

to SIZE-00236
set size 3
end

to-report update-attributes
ifElse my-next-infected-set
  [set my-infected my-next-infected
   set my-next-infected-set false]
  [set my-next-infected my-infected]
ifElse my-next-susceptibles-set
  [set my-susceptibles my-next-susceptibles
   set my-next-susceptibles-set false]
  [set my-next-susceptibles my-susceptibles]
ifElse my-next-recovered-set
  [set my-recovered my-next-recovered
   set my-next-recovered-set false]
  [set my-next-recovered my-recovered]
ifElse my-next-dead-set
  [set my-dead my-next-dead
   set my-next-dead-set false]
  [set my-next-dead my-dead]
ifElse my-next-others-set
  [set my-others my-next-others
   set my-next-others-set false]
  [set my-next-others my-others]
report false
end

to initialise-patch-attributes
 set log-patch-attributes []
end

to initialise-globals
 set the-initial-state [
[52.9 39.2 46986]
[77.6 65.1 53699]
[135.9 41.2 190882]
[65.3 50.5 220248]
[-116.5 64.3 11537]
[98.8 39.2 211983]
[-54.7 5 34023]
[3.5 43.6 759331]
[21.2 35.8 123465]
[134.1 42.3 138693]
[33.5 13 163613]
[24.7 -9.9 168228]
[26.5 40.7 1368894]
[3.5 18.2 79331]
[120 40.7 289469]
[97.1 39.2 355879]
[-88.2 66.8 10446]
[68.8 72 42455]
[38.8 67.7 50342]
[-120 67.7 15522]
[-22.9 65.1 185847]
[7.1 60 71318]
[8.8 37.6 643963]
[79.4 37.6 144399]
[49.4 18.2 43630]
[-86.5 37.1 447208]
[-8.8 9.1 654871]
[100.6 37.6 110334]
[52.9 40.2 53699]
[49.4 -15 62089]
[28.2 3 388056]
[-81.2 -4.5 629280]
[58.2 38.6 53699]
[42.4 40.7 316738]
[10.6 1 53699]
[40.6 66 50342]
[77.6 13 2454192]
[45.9 -18.4 1071035]
[28.2 16.5 144315]
[33.5 -18.4 205565]
[45.9 61.7 223604]
[-77.6 40.2 708150]
[-5.3 13 263459]
[112.9 39.2 2538096]
[26.5 -21.8 48077]
[-70.6 -2.7 14977]
[22.9 -2.7 65026]
[33.5 -21.8 234931]
[-70.6 -40.5 53699]
[14.1 35.8 58104]
[30 63.4 223185]
[8.8 46.4 2307360]
[-75.9 13 729965]
[125.3 40.7 2720587]
[112.9 47.8 53699]
[26.5 -6.3 110334]
[47.6 42.3 302054]
[54.7 29.4 560059]
[7.1 46.4 2705904]
[105.9 -4.5 1090752]
[-75.9 11.2 797088]
[-40.6 -2.7 302054]
[52.9 63.4 99007]
[-84.7 18.2 30205]
[49.4 27.4 22235]
[38.8 -11.7 234931]
[22.9 43.6 2559072]
[38.8 35.8 31212]
[5.3 11.2 969091]
[-104.1 34.3 17158]
[37.1 35.8 451445]
[146.5 -8.1 43630]
[15.9 43.6 2112283]
[51.2 20 53699]
[30 -8.1 73542]
[90 50.5 11537]
[12.4 1 53699]
[40.6 29.4 53699]
[72.4 29.4 2181504]
[79.4 23.5 2181504]
[37.1 -15 262200]
[139.4 60.9 13425]
[44.1 -18.4 43630]
[3.5 42.3 813869]
[51.2 69.4 11159]
[141.2 64.3 19969]
[70.6 27.4 1694861]
[24.7 5 53699]
[5.3 43.6 1011043]
[51.2 60.9 371275]
[7.1 13 1174656]
[70.6 63.4 53699]
[21.2 46.4 2055648]
[-75.9 40.7 378533]
[-65.3 -28.5 110334]
[37.1 5 53699]
[51.2 37.1 622987]
[35.3 45 2307360]
[137.6 -6.3 22864]
[28.2 5 234931]
[8.8 16.5 380505]
[5.3 38.1 1174656]
[15.9 40.2 71318]
[-112.9 29.4 23493]
[-91.8 40.7 140959]
[-67.1 -43.3 43630]
[-67.1 3 10991]
[56.5 64.3 53699]
[95.3 60 19969]
[-98.8 27.4 216137]
[42.4 5 200950]
[30 31.2 278687]
[24.7 40.2 797088]
[-52.9 -8.1 45266]
[40.6 34.3 53699]
[8.8 40.7 1279536]
[47.6 49.1 383861]
[-54.7 -8.1 42455]
[111.2 27.4 2538096]
[169.4 -44.6 63348]
[3.5 21.7 11537]
[47.6 29.4 31212]
[19.4 35.8 183582]
[-70.6 -15 169318]
[35.3 35.8 2405947]
[54.7 23.5 50888]
[114.7 62.6 48077]
[26.5 14.8 110334]
[63.5 31.2 121661]
[31.8 34.3 1362559]
[114.7 -8.1 377568]
[63.5 66.8 53699]
[42.4 32.7 53699]
[137.6 38.1 2181504]
[160.6 -8.1 14683]
[139.4 -33.4 39645]
[82.9 69.4 19969]
[22.9 70.2 39645]
[132.4 40.7 234931]
[111.2 5 59278]
[3.5 45 1908816]
[-56.5 -6.3 53699]
[75.9 62.6 53699]
[79.4 62.6 53699]
[-91.8 39.7 379246]
[100.6 29.4 2181504]
[35.3 62.6 210180]
[14.1 63.4 65026]
[-49.4 -11.7 87680]
[-107.6 39.2 50972]
[45.9 16.5 228638]
[139.4 47.8 50342]
[68.8 62.6 46986]
[17.6 9.1 53699]
[33.5 -11.7 267864]
[107.6 66 13802]
[123.5 14.8 839040]
[47.6 60 748843]
[-118.2 47.8 10991]
[100.6 31.2 650256]
[12.4 14.8 262200]
[52.9 67.7 53699]
[3.5 13 344006]
[-102.4 43.6 62299]
[-100.6 45 76353]
[134.1 47.8 53699]
[67.1 38.6 1300512]
[63.5 61.7 234931]
[45.9 66.8 53699]
[52.9 66.8 53699]
[97.1 60 53699]
[-44.1 -15 74884]
[30 -18.4 344006]
[40.6 63.4 53699]
[52.9 23.5 28402]
[12.4 64.3 11537]
[111.2 -6.3 1950768]
[61.8 32.7 53699]
[19.4 -26.8 36834]
[111.2 50.5 53699]
[107.6 61.7 53699]
[84.7 25.4 2684928]
[121.8 41.2 912456]
[-61.8 -25.1 53699]
[112.9 -8.1 167808]
[30 34.3 3056749]
[-109.4 29.4 341070]
[44.1 31.2 53699]
[19.4 43.6 1426368]
[-81.2 31.2 314892]
[-65.3 13 159418]
[37.1 37.6 1262755]
[-70.6 45 42455]
[24.7 -15 45266]
[19.4 69.4 36288]
[-84.7 25.4 71318]
[79.4 11.2 769819]
[98.8 50.5 43630]
[22.9 13 138693]
[90 29.4 1973842]
[24.7 47.8 1048800]
[-79.4 25.4 480057]
[19.4 39.7 1692763]
[58.2 66.8 53699]
[42.4 41.2 212277]
[-84.7 38.6 385958]
[-72.4 -35.1 274786]
[114.7 32.7 1971744]
[144.7 -6.3 46986]
[132.4 61.7 34023]
[-63.5 -9.9 67920]
[33.5 20 178296]
[75.9 23.5 2684928]
[63.5 37.1 189623]
[125.3 46.4 50342]
[-90 41.2 99007]
[7.1 60.9 14683]
[52.9 43.6 53699]
[47.6 32.7 574742]
[40.6 49.1 234931]
[26.5 66 59404]
[-105.9 69.4 13886]
[79.4 38.1 178296]
[8.8 50.5 910904]
[-70.6 -44.6 19969]
[47.6 60.9 234931]
[105.9 -0.9 224443]
[24.7 34.3 19969]
[24.7 63.4 92294]
[-65.3 7.1 39645]
[105.9 42.3 53699]
[109.4 -0.9 135505]
[125.3 41.2 2642976]
[40.6 3 132988]
[65.3 41.2 50888]
[109.4 61.7 45266]
[-72.4 11.2 952856]
[-1.8 38.1 167808]
[21.2 -15 34023]
[12.4 -2.7 144315]
[10.6 38.1 167808]
[75.9 50.5 220793]
[31.8 69.4 53699]
[-35.3 -6.3 419520]
[-5.3 37.1 1130187]
[-10.6 16.5 87680]
[-125.3 42.3 10068]
[21.2 60.9 224443]
[-45.9 -0.9 139406]
[-14.1 29.4 28402]
[42.4 49.1 234931]
[-155.3 61.7 10991]
[-112.9 39.2 102782]
[60 38.1 121661]
[38.8 27.4 87680]
[72.4 60 234931]
[61.8 60.9 234931]
[121.8 -2.7 241224]
[-102.4 35.8 122542]
[-68.8 -23.4 53699]
[5.3 47.8 2239230]
[-42.4 -11.7 178296]
[-68.8 -36.5 34023]
[37.1 60.9 455179]
[109.4 3 339811]
[-84.7 11.2 18039]
[-111.2 39.2 92462]
[26.5 46.4 1174656]
[-68.8 -44.6 18878]
[38.8 66 36918]
[14.1 41.2 769819]
[134.1 40.2 14683]
[-60 3 19969]
[68.8 45 197594]
[130.6 1 14515]
[-155.3 23.5 14683]
[-109.4 43.6 17158]
[-107.6 38.6 25591]
[44.1 -16.7 53699]
[19.4 -6.3 99007]
[-74.1 -36.5 392251]
[45.9 37.6 966994]
[97.1 23.5 661247]
[137.6 60 10068]
[111.2 49.1 53699]
[33.5 21.7 22780]
[17.6 -6.3 186267]
[58.2 31.2 121661]
[49.4 50.5 629825]
[142.9 40.7 377568]
[22.9 21.7 11537]
[111.2 32.7 2622000]
[58.2 37.6 234931]
[-123.5 45 332973]
[28.2 -28.5 795662]
[19.4 5 234931]
[52.9 49.1 262200]
[30 67.7 53699]
[-7.1 40.2 830650]
[-61.8 -31.8 205565]
[82.9 45 53699]
[-123.5 46.4 11537]
[33.5 64.3 50342]
[0 43.6 922944]
[-60 5 17158]
[8.8 60 883090]
[-60 -18.4 31212]
[5.3 61.7 68172]
[44.1 63.4 53699]
[44.1 67.7 40819]
[31.8 37.6 224443]
[109.4 21.7 880992]
[-75.9 5 753458]
[-81.2 -2.7 715282]
[-86.5 42.3 10068]
[-102.4 21.7 429169]
[137.6 46.4 50342]
[139.4 63.4 50888]
[-97.1 37.6 456270]
[75.9 18.2 2684928]
[79.4 70.2 34023]
[40.6 7.1 53699]
[75.9 60.9 76353]
[118.2 49.1 53699]
[-47.6 -20.1 1282598]
[3.5 46.4 2370288]
[24.7 1 53699]
[-58.2 3 50888]
[31.8 29.4 187400]
[-54.7 -21.8 187525]
[-58.2 -33.4 97161]
[26.5 47.8 671232]
[-105.9 29.4 45266]
[70.6 38.6 278939]
[-61.8 -26.8 144315]
[1.8 35.8 53699]
[26.5 43.6 1552224]
[47.6 9.1 160257]
[114.7 38.1 4153248]
[125.3 43.6 956506]
[-100.6 34.3 31296]
[19.4 -23.4 17158]
[-17.6 18.2 394349]
[33.5 46.4 1048800]
[-67.1 40.7 28108]
[104.1 32.7 2768832]
[65.3 69.4 36918]
[91.8 25.4 1282473]
[105.9 34.3 3880560]
[52.9 40.7 53699]
[17.6 69.4 42455]
[-44.1 -6.3 65026]
[-60 -30.1 220248]
[12.4 68.5 10068]
[-42.4 -8.1 53699]
[72.4 23.5 2116185]
[-56.5 -8.1 42455]
[118.2 39.2 2097600]
[7.1 37.1 189623]
[-102.4 42.3 34023]
[123.5 47.8 53699]
[-77.6 21.7 503424]
[-7.1 18.2 53699]
[28.2 64.3 70731]
[5.3 9.1 2391264]
[5.3 7.1 1510272]
[52.9 31.2 176198]
[74.1 34.3 3104448]
[112.9 49.1 53699]
[107.6 25.4 1845888]
[-63.5 -26.8 53699]
[81.2 61.7 53699]
[118.2 13 29912]
[54.7 25.4 53699]
[-118.2 35.8 167808]
[77.6 38.1 50888]
[3.5 40.7 1305966]
[104.1 -2.7 857918]
[44.1 50.5 643963]
[141.2 -6.3 53699]
[139.4 -0.9 16781]
[21.2 -16.7 19424]
[28.2 -16.7 212277]
[-12.4 16.5 80967]
[81.2 20 2475168]
[100.6 27.4 715282]
[-112.9 42.3 50972]
[98.8 35.8 53699]
[118.2 43.6 14348]
[19.4 70.2 70437]
[10.6 60.9 57181]
[58.2 65.1 53699]
[56.5 60 234931]
[72.4 41.2 35198]
[31.8 3 1136899]
[42.4 46.4 262200]
[40.6 61.7 144315]
[-63.5 -25.1 53699]
[-111.2 27.4 38176]
[-61.8 11.2 46986]
[24.7 -21.8 45266]
[-61.8 -18.4 31212]
[30 45 2559072]
[-120 38.1 375890]
[137.6 45 53699]
[30 13 187525]
[47.6 46.4 234931]
[60 29.4 40274]
[42.4 43.6 220793]
[81.2 31.2 3104448]
[-65.3 -33.4 178296]
[100.6 -2.7 41952]
[104.1 46.4 40274]
[22.9 38.6 401187]
[120 38.1 1803936]
[114.7 27.4 2978592]
[44.1 47.8 234931]
[-15.9 14.8 345643]
[42.4 34.3 103621]
[-63.5 -35.1 562157]
[98.8 60 43630]
[-72.4 -39.2 118305]
[33.5 -6.3 234931]
[81.2 39.7 1425948]
[-65.3 9.1 53699]
[79.4 43.6 53699]
[-60 -31.8 234931]
[-121.8 38.1 1251428]
[47.6 62.6 155642]
[3.5 41.2 1902523]
[100.6 40.7 14348]
[47.6 27.4 62215]
[-120 47.8 48077]
[-44.1 -18.4 167221]
[47.6 65.1 53699]
[-67.1 66 10446]
[56.5 38.1 209466]
[8.8 39.7 98587]
[-22.9 66 11075]
[56.5 71.1 10068]
[5.3 13 398544]
[15.9 40.7 671232]
[28.2 20 53699]
[-51.2 -23.4 671232]
[75.9 13 2978592]
[-86.5 41.2 20137]
[45.9 41.2 69724]
[40.6 32.7 53699]
[127.1 -2.7 29366]
[118.2 40.7 205565]
[26.5 -30.1 473470]
[91.8 40.7 53699]
[-7.1 13 403998]
[30 -21.8 493859]
[-91.8 35.8 310025]
[98.8 47.8 53699]
[81.2 66.8 53699]
[72.4 63.4 53699]
[-65.3 -40.5 20137]
[-88.2 39.2 239546]
[22.9 -21.8 19969]
[-52.9 -23.4 671232]
[-93.5 40.2 144315]
[35.3 23.5 19969]
[116.5 32.7 2642976]
[31.8 -11.7 477833]
[141.2 47.8 40274]
[35.3 -9.9 220248]
[-88.2 16.5 1080264]
[14.1 14.8 1350015]
[42.4 31.2 53699]
[-86.5 38.6 785761]
[84.7 47.8 234931]
[22.9 14.8 234931]
[14.1 68.5 50300]
[12.4 50.5 209760]
[-104.1 31.2 36834]
[130.6 40.7 680168]
[60 60.9 234931]
[10.6 40.7 2684928]
[-3.5 38.1 335616]
[-102.4 38.1 31212]
[44.1 41.2 82142]
[137.6 -4.5 46986]
[120 27.4 1231291]
[-60 -15 50972]
[28.2 -23.4 790879]
[93.5 31.2 1567746]
[-118.2 40.7 27856]
[63.5 39.7 234931]
[105.9 -6.3 937627]
[17.6 41.2 1552224]
[33.5 32.7 18333]
[82.9 31.2 3314208]
[-118.2 46.4 19969]
[72.4 18.2 335616]
[5.3 63.4 76353]
[114.7 -33.4 37002]
[75.9 38.1 50972]
[33.5 -16.7 388056]
[33.5 49.1 316738]
[10.6 43.6 1510272]
[128.8 41.2 688013]
[-72.4 13 338259]
[63.5 62.6 76353]
[134.1 40.7 190882]
[75.9 21.7 2684928]
[26.5 40.2 671232]
[24.7 50.5 1048800]
[86.5 39.7 240888]
[-146.5 63.4 10991]
[-5.3 46.4 731223]
[120 46.4 121661]
[88.2 39.7 59572]
[30 -4.5 234931]
[127.1 45 212529]
[-52.9 5 31212]
[84.7 42.3 59404]
[37.1 47.8 507619]
[38.8 38.1 759331]
[120 34.3 2349857]
[-75.9 40.2 556284]
[60 35.8 155642]
[77.6 49.1 200950]
[-125.3 43.6 72157]
[61.8 31.2 87680]
[-49.4 -18.4 375974]
[30 -15 118305]
[-91.8 21.7 86841]
[-104.1 38.6 122542]
[109.4 38.6 1218706]
[105.9 64.3 53699]
[65.3 61.7 110334]
[-109.4 37.1 28402]
[31.8 60.9 234931]
[-81.2 37.6 732062]
[61.8 70.2 23493]
[72.4 21.7 1243038]
[102.4 45 25591]
[-58.2 -28.5 263459]
[-67.1 67.7 10530]
[8.8 7.1 763233]
[28.2 68.5 17158]
[68.8 37.6 857918]
[77.6 45 53699]
[-7.1 35.8 1109630]
[61.8 39.2 525659]
[74.1 16.5 1887840]
[63.5 50.5 234931]
[56.5 23.5 46986]
[30 32.7 931125]
[21.2 42.3 1174656]
[22.9 45 2181504]
[40.6 41.2 453082]
[1.8 39.2 182491]
[-100.6 46.4 41910]
[118.2 50.5 53699]
[58.2 35.8 234931]
[121.8 49.1 53699]
[45.9 66 53699]
[-74.1 -41.9 102782]
[14.1 62.6 160257]
[38.8 -13.4 507619]
[-74.1 39.2 440496]
[-112.9 38.1 28402]
[17.6 -11.7 127366]
[137.6 62.6 36834]
[1.8 16.5 742131]
[15.9 -15 42455]
[30 66.8 53699]
[12.4 13 813869]
[-91.8 38.1 87680]
[28.2 -15 701983]
[7.1 42.3 2684928]
[-47.6 -23.4 839040]
[104.1 61.7 50888]
[-111.2 41.2 41994]
[45.9 -23.4 138861]
[12.4 16.5 118389]
[-58.2 -0.9 27856]
[123.5 46.4 53699]
[109.4 50.5 44175]
[65.3 37.1 234931]
[105.9 31.2 2559072]
[35.3 50.5 1487198]
[-51.2 -26.8 212277]
[70.6 39.7 1793448]
[17.6 13 121661]
[60 62.6 234931]
[-74.1 11.2 1218706]
[-105.9 23.5 141378]
[5.3 40.7 1048380]
[81.2 49.1 234931]
[172.9 -35.1 49503]
[35.3 39.7 1048800]
[54.7 43.6 53699]
[75.9 47.8 53699]
[47.6 64.3 53699]
[100.6 7.1 1623542]
[111.2 45 48077]
[54.7 27.4 137603]
[107.6 37.6 1722130]
[82.9 61.7 53699]
[58.2 39.7 76353]
[-3.5 13 727448]
[97.1 43.6 11537]
[-109.4 37.6 42455]
[45.9 49.1 234931]
[111.2 31.2 3419088]
[54.7 50.5 234931]
[33.5 67.7 36918]
[-95.3 39.2 414486]
[8.8 43.6 2663952]
[15.9 -23.4 19969]
[61.8 67.7 53699]
[15.9 39.7 880992]
[67.1 41.2 45266]
[30 49.1 1065581]
[0 47.8 2013696]
[45.9 23.5 212277]
[42.4 50.5 562157]
[75.9 11.2 1321488]
[8.8 63.4 65026]
[132.4 60.9 53699]
[60 32.7 53699]
[67.1 61.7 43630]
[109.4 60.9 53699]
[7.1 39.2 29366]
[68.8 34.3 371275]
[79.4 13 545376]
[61.8 61.7 234931]
[40.6 62.6 53699]
[26.5 -2.7 226121]
[58.2 45 53699]
[98.8 31.2 1114245]
[60 31.2 53699]
[58.2 34.3 212277]
[-105.9 43.6 19969]
[81.2 42.3 53699]
[-45.9 -2.7 271429]
[139.4 46.4 30205]
[70.6 61.7 53699]
[15.9 49.1 602011]
[-125.3 39.7 21396]
[-67.1 -33.4 53699]
[-82.9 43.6 19969]
[81.2 69.4 53699]
[42.4 38.6 248062]
[112.9 38.6 2391264]
[63.5 60 223604]
[37.1 66 40274]
[67.1 60 53699]
[68.8 63.4 50342]
[109.4 60 53699]
[15.9 -18.4 11537]
[102.4 18.2 2684928]
[-107.6 46.4 67920]
[42.4 7.1 65026]
[116.5 38.1 3167376]
[77.6 31.2 3565920]
[8.8 3 57474]
[60 40.2 53699]
[114.7 25.4 167808]
[-12.4 31.2 36834]
[22.9 11.2 25591]
[167.6 -43.3 25045]
[120 35.8 3272256]
[-7.1 25.4 11537]
[93.5 47.8 48077]
[17.6 49.1 1887840]
[-3.5 7.1 643963]
[63.5 69.4 53699]
[31.8 -20.1 234931]
[54.7 71.1 40274]
[146.5 -37.8 14683]
[-47.6 -9.9 50888]
[-52.9 7.1 23493]
[37.1 -0.9 430260]
[105.9 38.6 1079551]
[15.9 64.3 126821]
[-102.4 64.3 11537]
[35.3 42.3 797088]
[21.2 9.1 34023]
[141.2 75.6 13257]
[31.8 11.2 212277]
[37.1 42.3 1441051]
[56.5 38.6 106978]
[74.1 61.7 53699]
[79.4 39.7 155642]
[-88.2 40.7 452243]
[-105.9 32.7 94812]
[35.3 65.1 53699]
[118.2 -0.9 136764]
[-112.9 38.6 22780]
[116.5 42.3 11537]
[-74.1 -43.3 12711]
[-52.9 42.3 14683]
[-51.2 1 70186]
[33.5 68.5 53699]
[-104.1 27.4 164158]
[120 -8.1 98587]
[67.1 40.7 53699]
[-61.8 -36.5 671232]
[82.9 67.7 31212]
[112.9 61.7 50888]
[169.4 -43.3 43714]
[107.6 21.7 685915]
[19.4 66 90574]
[81.2 47.8 234931]
[21.2 -11.7 22780]
[44.1 13 132694]
[102.4 -55.5 12166]
[22.9 65.1 106978]
[68.8 68.5 53699]
[-63.5 -39.2 481609]
[54.7 40.7 53699]
[-114.7 38.1 211061]
[-77.6 37.6 403159]
[-116.5 34.3 35911]
[22.9 40.2 918749]
[33.5 60.9 234931]
[37.1 20 132988]
[97.1 60.9 42455]
[31.8 42.3 643963]
[3.5 14.8 1300512]
[70.6 67.7 26849]
[-120 39.7 82142]
[109.4 46.4 53699]
[35.3 49.1 425813]
[-3.5 42.3 422876]
[-97.1 34.3 340650]
[61.8 41.2 53699]
[139.4 -4.5 53699]
[40.6 64.3 53699]
[72.4 71.1 16781]
[-72.4 -15 223604]
[81.2 60.9 53699]
[-88.2 40.2 434203]
[105.9 32.7 3419088]
[-15.9 16.5 996360]
[1.8 18.2 31212]
[44.1 61.7 189623]
[-68.8 -25.1 53699]
[-84.7 35.8 128625]
[37.1 32.7 17158]
[-49.4 -25.1 226541]
[-84.7 41.2 72703]
[31.8 18.2 784083]
[-1.8 43.6 1342464]
[-68.8 -13.4 212277]
[121.8 47.8 53699]
[31.8 16.5 1038312]
[-63.5 13 343167]
[67.1 35.8 376729]
[-7.1 9.1 574742]
[-8.8 46.4 14683]
[-112.9 37.6 53699]
[102.4 37.1 65026]
[49.4 13 46986]
[75.9 65.1 53699]
[51.2 40.2 30205]
[19.4 39.2 813869]
[17.6 40.7 671232]
[-7.1 38.6 442594]
[74.1 71.1 50888]
[118.2 1 251712]
[31.8 5 289469]
[-137.6 62.6 11537]
[-105.9 25.4 127073]
[38.8 49.1 551669]
[49.4 46.4 155642]
[-47.6 -8.1 45266]
[1.8 37.1 99007]
[51.2 21.7 48077]
[-111.2 31.2 368339]
[51.2 18.2 13425]
[72.4 69.4 20682]
[63.5 64.3 53699]
[12.4 42.3 1552224]
[56.5 46.4 189623]
[146.5 62.6 14348]
[-120 50.5 28402]
[19.4 47.8 1132704]
[49.4 38.1 1650811]
[148.2 -35.1 27311]
[84.7 45 87680]
[121.8 13 853723]
[98.8 3 736677]
[72.4 43.6 11537]
[-75.9 -8.1 118305]
[-116.5 72 10991]
[31.8 61.7 344006]
[52.9 68.5 44175]
[35.3 41.2 224443]
[28.2 1 839040]
[93.5 25.4 682140]
[84.7 43.6 53699]
[-109.4 49.1 53699]
[95.3 5 29366]
[65.3 31.2 76353]
[68.8 66.8 53699]
[19.4 40.7 2181504]
[95.3 20 1594176]
[-84.7 43.6 42455]
[63.5 29.4 130890]
[7.1 16.5 1011043]
[49.4 47.8 742550]
[118.2 7.1 44050]
[17.6 3 65823]
[42.4 9.1 99007]
[15.9 65.1 39645]
[33.5 -20.1 220248]
[17.6 -30.1 18333]
[60 68.5 53699]
[52.9 25.4 48077]
[-98.8 20 302054]
[-100.6 38.6 53321]
[70.6 39.2 1820717]
[-111.2 37.6 53699]
[5.3 37.6 1038312]
[17.6 16.5 53699]
[14.1 5 53699]
[15.9 -9.9 234931]
[3.5 38.1 1321488]
[93.5 49.1 17158]
[40.6 47.8 289469]
[-75.9 -11.7 776112]
[146.5 63.4 14348]
[42.4 66 53699]
[-98.8 18.2 14683]
[139.4 45 26849]
[10.6 9.1 726189]
[0 39.7 270590]
[37.1 46.4 671232]
[137.6 -35.1 171710]
[127.1 39.7 1290024]
[107.6 -6.3 2496144]
[112.9 38.1 2496144]
[150 -4.5 23493]
[-74.1 7.1 1683534]
[-88.2 14.8 41952]
[44.1 60.9 507619]
[100.6 -0.9 568156]
[120 49.1 53699]
[21.2 -26.8 48077]
[51.2 31.2 58733]
[-164.1 66.8 11537]
[-105.9 40.2 22780]
[54.7 42.3 53699]
[144.7 40.2 41952]
[-74.1 -15 146832]
[68.8 39.2 1164168]
[74.1 45 212277]
[17.6 -28.5 34023]
[-132.4 49.1 17326]
[-67.1 -15 141588]
[-44.1 -9.9 42455]
[47.6 38.1 857918]
[17.6 68.5 34107]
[-5.3 39.7 353236]
[130.6 40.2 102782]
[127.1 50.5 45266]
[105.9 45 53699]
[-102.4 32.7 34023]
[141.2 63.4 53699]
[-49.4 -21.8 2684928]
[120 16.5 706891]
[-74.1 69.4 11537]
[-1.8 40.7 731056]
[-95.3 41.2 308767]
[35.3 67.7 46986]
[8.8 31.2 11537]
[100.6 23.5 178296]
[-8.8 14.8 761429]
[148.2 -30.1 34023]
[22.9 63.4 493062]
[31.8 -23.4 312542]
[-51.2 -2.7 53699]
[105.9 18.2 316738]
[31.8 -8.1 365402]
[54.7 34.3 189623]
[135.9 49.1 37463]
[37.1 38.6 868406]
[91.8 29.4 2073687]
[-5.3 9.1 453082]
[114.7 45 28402]
[-47.6 -15 104712]
[109.4 39.2 891900]
[-121.8 39.7 50510]
[79.4 32.7 2517120]
[97.1 5 271681]
[54.7 66 53699]
[-56.5 -26.8 174940]
[24.7 7.1 39645]
[35.3 5 45266]
[8.8 9.1 912456]
[70.6 46.4 53699]
[-56.5 -16.7 25591]
[109.4 40.2 25591]
[15.9 5 48161]
[100.6 34.3 132988]
[-114.7 43.6 50888]
[121.8 11.2 671232]
[44.1 18.2 1962515]
[21.2 -31.8 31212]
[-75.9 9.1 922944]
[-60 -36.5 671232]
[8.8 35.8 36834]
[33.5 63.4 594879]
[111.2 25.4 2391264]
[-14.1 23.5 11537]
[52.9 72 42455]
[135.9 60 50342]
[-63.5 -16.7 53699]
[-88.2 18.2 744648]
[24.7 11.2 17158]
[26.5 70.2 11537]
[12.4 40.2 1231291]
[107.6 63.4 53699]
[19.4 -4.5 289469]
[67.1 66.8 53699]
[30 43.6 671232]
[28.2 40.7 434203]
[-65.3 -21.8 65026]
[-112.9 32.7 62634]
[-44.1 -16.7 79247]
[-54.7 -23.4 622148]
[79.4 66 53699]
[130.6 37.6 167808]
[79.4 37.1 28485]
[-74.1 39.7 2726880]
[-1.8 20 36834]
[-45.9 -20.1 195496]
[-68.8 -35.1 48077]
[134.1 61.7 45266]
[105.9 29.4 2160528]
[24.7 43.6 1552224]
[-84.7 34.3 273233]
[-93.5 38.6 336036]
[-93.5 39.2 61669]
[116.5 -33.4 31212]
[172.9 -40.5 34820]
[81.2 71.1 10446]
[38.8 -0.9 50342]
[135.9 37.1 335616]
[72.4 70.2 17326]
[-7.1 60.9 32555]
[82.9 46.4 189623]
[37.1 -8.1 132988]
[-88.2 21.7 80128]
[-40.6 -16.7 188784]
[-58.2 -21.8 90113]
[60 37.1 212277]
[28.2 63.4 439489]
[38.8 5 53699]
[-40.6 -6.3 255488]
[74.1 14.8 922944]
[12.4 38.6 503424]
[42.4 -23.4 29366]
[30 16.5 216892]
[97.1 37.1 39645]
[128.8 46.4 53699]
[-114.7 38.6 11537]
[26.5 16.5 67920]
[70.6 45 212277]
[88.2 60 144315]
[-112.9 34.3 27311]
[-65.3 40.7 76059]
[-97.1 21.7 643963]
[-109.4 76.4 12711]
[-72.4 -11.7 116123]
[-107.6 38.1 48077]
[19.4 49.1 1132704]
[14.1 42.3 1273243]
[-97.1 39.2 65026]
[52.9 34.3 212277]
[-65.3 -23.4 76353]
[30 14.8 189623]
[107.6 49.1 17326]
[14.1 3 31212]
[105.9 14.8 817057]
[40.6 31.2 53699]
[-63.5 -13.4 42455]
[47.6 35.8 589426]
[58.2 61.7 234931]
[17.6 11.2 166969]
[-98.8 40.2 53699]
[17.6 70.2 47238]
[116.5 39.2 2957616]
[42.4 29.4 53699]
[116.5 31.2 1986427]
[42.4 37.1 218318]
[-65.3 -30.1 234931]
[-60 -26.8 260102]
[19.4 -2.7 132988]
[44.1 -23.4 208921]
[102.4 60.9 50342]
[-52.9 1 25591]
[-63.5 5 19969]
[128.8 37.1 441041]
[114.7 5 95651]
[30 64.3 229477]
[10.6 -0.9 73542]
[97.1 14.8 71318]
[61.8 43.6 53699]
[-68.8 -55.5 12166]
[104.1 1 171164]
[21.2 41.2 769819]
[47.6 18.2 53699]
[-5.3 43.6 518107]
[132.4 49.1 53699]
[-56.5 46.4 13970]
[-121.8 45 50888]
[-68.8 -40.5 53699]
[100.6 41.2 25591]
[-51.2 -8.1 53699]
[-75.9 7.1 2181504]
[30 39.2 732062]
[160.6 -9.9 14683]
[105.9 35.8 2894688]
[-63.5 -23.4 50888]
[-120 40.7 11537]
[107.6 39.2 218234]
[-65.3 -37.8 31212]
[75.9 66.8 53699]
[-93.5 37.1 144315]
[111.2 35.8 2642976]
[44.1 62.6 53699]
[44.1 64.3 53699]
[67.1 49.1 189623]
[52.9 42.3 53699]
[104.1 14.8 1680723]
[-60 -2.7 18333]
[102.4 1 289175]
[-70.6 -0.9 17158]
[-54.7 45 13425]
[-77.6 62.6 10446]
[-125.3 40.2 36079]
[65.3 39.7 234931]
[-90 16.5 1552224]
[-95.3 37.1 121661]
[-111.2 38.1 36834]
[-54.7 -2.7 53699]
[-75.9 39.7 1071035]
[30 21.7 45266]
[-3.5 46.4 2286384]
[38.8 34.3 53699]
[-72.4 -0.9 28402]
[0 37.6 646061]
[-77.6 23.5 1050898]
[-116.5 41.2 25675]
[105.9 46.4 53699]
[42.4 -21.8 88099]
[37.1 65.1 50342]
[81.2 29.4 4258128]
[86.5 60.9 53699]
[-68.8 -30.1 53699]
[38.8 25.4 182911]
[60 39.7 1105016]
[120 14.8 41952]
[-123.5 38.6 333099]
[0 21.7 14348]
[-68.8 40.7 65445]
[-8.8 13 186267]
[142.9 -36.5 106516]
[7.1 38.1 1342464]
[82.9 47.8 234931]
[120 47.8 110334]
[65.3 63.4 53699]
[56.5 37.6 172674]
[38.8 42.3 1132704]
[-95.3 40.2 132988]
[128.8 40.7 803381]
[-68.8 43.6 76059]
[-67.1 -11.7 17158]
[75.9 42.3 23955]
[3.5 11.2 1749398]
[17.6 -33.4 87260]
[95.3 39.7 28402]
[63.5 49.1 72996]
[35.3 20 144315]
[-95.3 20 338930]
[-75.9 -4.5 53699]
[31.8 -25.1 868406]
[-51.2 -25.1 441755]
[31.8 64.3 53699]
[65.3 62.6 53699]
[-67.1 -21.8 144315]
[-100.6 32.7 70731]
[45.9 64.3 53699]
[54.7 61.7 234931]
[47.6 41.2 73416]
[120 29.4 440496]
[-77.6 43.6 42455]
[45.9 40.2 398544]
[52.9 32.7 234931]
[93.5 35.8 36834]
[61.8 37.1 178296]
[121.8 3 211858]
[104.1 -4.5 797633]
[0 41.2 616694]
[44.1 40.2 1273243]
[-112.9 47.8 114948]
[15.9 -0.9 46986]
[33.5 -15 1198149]
[104.1 31.2 2531803]
[35.3 66 13425]
[-47.6 -11.7 65026]
[-77.6 41.2 80506]
[-72.4 -9.9 28402]
[-12.4 9.1 127954]
[70.6 60.9 174940]
[26.5 -0.9 303313]
[104.1 74.7 10991]
[104.1 43.6 48077]
[102.4 7.1 266395]
[-14.1 20 53699]
[91.8 39.7 11537]
[47.6 50.5 827000]
[-63.5 -28.5 99007]
[14.1 -2.7 12166]
[95.3 7.1 379666]
[12.4 45 1803936]
[58.2 60 262200]
[33.5 60 289469]
[-67.1 13 1207379]
[74.1 39.7 76353]
[164.1 -20.1 16781]
[-118.2 43.6 67920]
[93.5 32.7 36834]
[38.8 47.8 1174656]
[137.6 49.1 26849]
[45.9 63.4 65026]
[26.5 34.3 11537]
[123.5 49.1 53699]
[10.6 16.5 84953]
[75.9 71.1 50888]
[5.3 16.5 966994]
[38.8 66.8 10614]
[56.5 21.7 23493]
[24.7 31.2 11537]
[28.2 66 53699]
[142.9 -4.5 53699]
[107.6 45 53699]
[112.9 50.5 53699]
[-51.2 3 25759]
[118.2 37.6 2789808]
[88.2 25.4 2747856]
[-74.1 1 45266]
[-14.1 11.2 560059]
[100.6 32.7 153544]
[100.6 38.1 462143]
[21.2 38.6 396992]
[-58.2 43.6 42455]
[77.6 14.8 3104448]
[-70.6 41.2 87764]
[128.8 40.2 1208218]
[40.6 65.1 53699]
[105.9 49.1 50342]
[-5.3 61.7 10068]
[-114.7 45 68004]
[28.2 38.6 1174656]
[-63.5 7.1 53699]
[21.2 -25.1 16613]
[-1.8 37.6 1021531]
[-107.6 32.7 150188]
[15.9 61.7 480350]
[-70.6 39.7 167808]
[30 7.1 99007]
[45.9 -15 137603]
[-56.5 5 17158]
[111.2 -2.7 29912]
[109.4 64.3 22780]
[-65.3 -15 87764]
[77.6 60.9 65026]
[100.6 21.7 340650]
[72.4 40.2 337294]
[-5.3 45 503424]
[-47.6 -18.4 228009]
[65.3 29.4 19508]
[70.6 66.8 53699]
[144.7 -35.1 42078]
[15.9 39.2 853723]
[22.9 -11.7 42455]
[86.5 46.4 166969]
[-123.5 40.2 155642]
[109.4 31.2 2559072]
[31.8 49.1 748843]
[-146.5 66.8 34023]
[70.6 40.2 252132]
[-52.9 -4.5 53699]
[52.9 35.8 166969]
[79.4 39.2 166969]
[-82.9 38.6 516429]
[-74.1 -11.7 234931]
[155.3 50.5 11537]
[54.7 62.6 234931]
[49.4 11.2 26849]
[72.4 37.6 2099698]
[-10.6 18.2 144315]
[142.9 -6.3 46986]
[75.9 69.4 36918]
[116.5 1 31464]
[24.7 3 53699]
[21.2 -8.1 53699]
[-14.1 13 732062]
[51.2 38.1 1006848]
[-139.4 62.6 10991]
[-81.2 39.2 891900]
[44.1 35.8 1278697]
[-54.7 -28.5 234931]
[104.1 38.6 11537]
[8.8 37.1 296601]
[15.9 -4.5 209466]
[141.2 43.6 20137]
[14.1 -15 87680]
[82.9 60 95651]
[-61.8 -13.4 50888]
[-70.6 -9.9 17158]
[-7.1 49.1 1273243]
[49.4 21.7 34023]
[-7.1 38.1 1231291]
[-67.1 -16.7 178296]
[52.9 50.5 453082]
[1.8 34.3 42455]
[24.7 66 128079]
[38.8 16.5 803381]
[21.2 47.8 1384416]
[95.3 49.1 50888]
[45.9 -20.1 463947]
[90 35.8 11537]
[116.5 38.6 2265408]
[30 -2.7 1055093]
[40.6 40.2 922944]
[30 65.1 53699]
[49.4 67.7 53699]
[51.2 49.1 589426]
[-91.8 38.6 604948]
[-112.9 35.8 371275]
[-42.4 -13.4 228219]
[112.9 45 28402]
[134.1 50.5 43630]
[17.6 -21.8 31212]
[67.1 62.6 53699]
[70.6 70.2 53699]
[116.5 50.5 53699]
[10.6 42.3 1678080]
[22.9 18.2 22780]
[1.8 14.8 179555]
[60 66.8 53699]
[-68.8 -52.8 50342]
[77.6 64.3 53699]
[114.7 34.3 2559072]
[107.6 65.1 48077]
[-81.2 11.2 280659]
[141.2 -8.1 26849]
[120 40.2 715282]
[-37.1 -8.1 1078166]
[-58.2 9.1 242483]
[70.6 32.7 1875254]
[-102.4 25.4 589006]
[61.8 42.3 53699]
[114.7 39.7 994262]
[-38.8 -4.5 348621]
[60 63.4 223604]
[86.5 40.7 238539]
[116.5 37.6 3880560]
[51.2 50.5 797088]
[102.4 3 518653]
[60 42.3 43630]
[22.9 68.5 19969]
[139.4 38.6 2014241]
[19.4 -18.4 19969]
[15.9 67.7 17158]
[47.6 40.2 14683]
[-12.4 29.4 10991]
[121.8 60 39645]
[0 11.2 706891]
[22.9 64.3 96196]
[-160.6 50.5 10614]
[118.2 45 62299]
[58.2 49.1 371275]
[21.2 1 53699]
[79.4 25.4 2433216]
[68.8 39.7 2252822]
[33.5 42.3 1021531]
[134.1 -13.4 10446]
[67.1 27.4 61627]
[-172.9 -13.4 167808]
[105.9 72.9 11537]
[14.1 11.2 194238]
[49.4 42.3 40274]
[139.4 -36.5 32387]
[61.8 40.2 212277]
[70.6 69.4 53699]
[137.6 -33.4 34652]
[42.4 66.8 50888]
[14.1 25.4 14348]
[-54.7 -6.3 53699]
[72.4 49.1 122919]
[116.5 60 53699]
[-81.2 38.6 218150]
[72.4 27.4 2684928]
[-1.8 49.1 2120674]
[12.4 39.7 1231291]
[17.6 -9.9 132988]
[134.1 60 53699]
[-58.2 -18.4 30667]
[127.1 39.2 1342464]
[38.8 50.5 2280091]
[-104.1 46.4 70815]
[-1.8 18.2 50972]
[1.8 43.6 2043062]
[-38.8 -9.9 361207]
[28.2 65.1 50888]
[-120 46.4 50888]
[79.4 64.3 53699]
[72.4 32.7 1596274]
[79.4 69.4 53699]
[38.8 45 1803936]
[12.4 63.4 36834]
[107.6 1 15229]
[26.5 67.7 31212]
[109.4 65.1 13802]
[-116.5 45 53699]
[-114.7 35.8 246678]
[35.3 9.1 695270]
[7.1 18.2 53782]
[19.4 1 53699]
[-68.8 -31.8 53699]
[74.1 46.4 53699]
[-81.2 40.7 318542]
[17.6 1 43630]
[111.2 38.6 1860571]
[100.6 25.4 417842]
[35.3 -16.7 220248]
[-81.2 41.2 25129]
[10.6 3 99007]
[-123.5 42.3 482448]
[26.5 -13.4 48161]
[-84.7 37.1 777371]
[21.2 38.1 241224]
[26.5 -8.1 234931]
[100.6 42.3 48077]
[61.8 39.7 776112]
[77.6 11.2 503424]
[86.5 32.7 19969]
[15.9 3 14348]
[81.2 70.2 17158]
[58.2 29.4 75514]
[49.4 62.6 76353]
[-75.9 3 240804]
[5.3 18.2 76520]
[10.6 37.1 71318]
[-49.4 -26.8 275205]
[-45.9 -6.3 45266]
[88.2 45 61669]
[-112.9 43.6 28402]
[-112.9 40.2 61753]
[-7.1 14.8 266815]
[97.1 50.5 53699]
[100.6 43.6 36834]
[104.1 -0.9 64984]
[-49.4 -9.9 53699]
[28.2 -18.4 172129]
[128.8 42.3 1279536]
[15.9 16.5 65026]
[84.7 50.5 234931]
[49.4 60.9 234931]
[21.2 63.4 166675]
[70.6 29.4 966994]
[-86.5 40.2 843235]
[26.5 64.3 78702]
[52.9 66 53699]
[98.8 38.1 39099]
[21.2 -13.4 42455]
[84.7 64.3 31212]
[123.5 60 17158]
[49.4 37.6 1262755]
[30 -6.3 160802]
[17.6 60.9 33268]
[118.2 -8.1 224443]
[-72.4 -13.4 234931]
[-14.1 31.2 26849]
[-37.1 -9.9 251712]
[-70.6 -50.1 11537]
[28.2 -11.7 604948]
[49.4 20 53699]
[-61.8 -16.7 53699]
[-49.4 -15 234931]
[102.4 5 186686]
[14.1 61.7 331673]
[33.5 41.2 1778765]
[81.2 65.1 53699]
[30 39.7 560059]
[72.4 37.1 2873712]
[114.7 9.1 14683]
[-98.8 38.1 50426]
[97.1 38.6 25591]
[155.3 63.4 11075]
[12.4 -4.5 1217447]
[120 -2.7 423715]
[141.2 40.7 380211]
[118.2 34.3 2789808]
[12.4 18.2 11537]
[81.2 38.6 76353]
[-65.3 -20.1 99007]
[86.5 42.3 62299]
[102.4 61.7 43630]
[28.2 69.4 42455]
[67.1 37.1 262200]
[56.5 39.2 53699]
[21.2 -0.9 76353]
[104.1 35.8 1925597]
[37.1 14.8 1539638]
[-148.2 66.8 17158]
[-70.6 21.7 980125]
[-45.9 -9.9 45266]
[0 9.1 1220510]
[-75.9 38.6 131310]
[56.5 47.8 234931]
[-68.8 13 748004]
[-111.2 46.4 11537]
[-1.8 9.1 1102918]
[22.9 34.3 48077]
[-70.6 40.7 411130]
[-95.3 40.7 144315]
[88.2 42.3 67375]
[137.6 41.2 14683]
[28.2 -0.9 1741008]
[33.5 25.4 11537]
[93.5 23.5 1404553]
[-67.1 -52.8 23493]
[102.4 23.5 458535]
[81.2 27.4 2433216]
[77.6 50.5 234931]
[28.2 -13.4 186602]
[74.1 37.1 234931]
[77.6 35.8 110418]
[24.7 13 79247]
[49.4 66.8 53699]
[75.9 37.6 223604]
[100.6 9.1 1048800]
[75.9 68.5 50342]
[77.6 46.4 53699]
[-8.8 20 50888]
[31.8 -16.7 442594]
[61.8 38.1 53699]
[82.9 25.4 2307360]
[-7.1 37.6 671232]
[10.6 62.6 561737]
[77.6 66.8 53699]
[-125.3 39.2 14683]
[75.9 66 53699]
[-127.1 45 35198]
[-56.5 1 53699]
[81.2 64.3 53699]
[51.2 40.7 53699]
[111.2 60.9 53699]
[-75.9 43.6 17158]
[14.1 39.7 1573200]
[176.5 -16.7 167808]
[-82.9 41.2 15061]
[54.7 37.6 11537]
[28.2 -30.1 1110889]
[72.4 34.3 3419088]
[45.9 42.3 288462]
[44.1 23.5 234931]
[114.7 29.4 2559072]
[-61.8 9.1 36288]
[45.9 29.4 166969]
[60 46.4 171584]
[-82.9 39.7 694306]
[125.3 37.6 627434]
[135.9 42.3 110334]
[116.5 35.8 2936640]
[40.6 60.9 620890]
[31.8 38.1 576840]
[-70.6 -18.4 36918]
[67.1 66 53699]
[65.3 38.1 596977]
[-56.5 -0.9 51601]
[-49.4 -0.9 53699]
[107.6 40.2 17158]
[-45.9 -15 39183]
[100.6 60 30751]
[-3.5 39.2 723378]
[31.8 -26.8 269038]
[123.5 11.2 1090752]
[-63.5 9.1 53699]
[-84.7 38.1 220248]
[-72.4 40.7 178296]
[114.7 60.9 53699]
[81.2 34.3 36918]
[120 39.7 1594176]
[-79.4 -6.3 853723]
[33.5 16.5 594712]
[174.7 -39.2 110040]
[40.6 42.3 994262]
[45.9 18.2 84869]
[56.5 41.2 53699]
[-61.8 -30.1 220248]
[98.8 20 742550]
[14.1 49.1 643963]
[26.5 -11.7 309564]
[95.3 27.4 742131]
[121.8 38.1 335616]
[-86.5 37.6 695564]
[-8.8 11.2 223604]
[47.6 61.7 234931]
[-74.1 -40.5 73416]
[121.8 50.5 53699]
[19.4 16.5 53699]
[79.4 9.1 2097600]
[125.3 39.2 2154235]
[141.2 41.2 45308]
[-54.7 -33.4 38176]
[60 39.2 53699]
[31.8 -21.8 234931]
[26.5 60 759331]
[128.8 39.7 1174656]
[127.1 47.8 53699]
[47.6 47.8 497131]
[5.3 41.2 1776667]
[51.2 37.6 2496564]
[-81.2 40.2 658646]
[42.4 40.2 1147387]
[68.8 65.1 53699]
[74.1 27.4 2684928]
[75.9 37.1 234931]
[120 -9.9 14683]
[-77.6 -8.1 388056]
[-68.8 -18.4 53699]
[111.2 3 178296]
[21.2 5 223604]
[-3.5 40.2 939725]
[44.1 37.1 1182207]
[-102.4 27.4 53782]
[21.2 -2.7 178296]
[121.8 72.9 10991]
[7.1 62.6 25591]
[102.4 27.4 2307360]
[84.7 32.7 49587]
[40.6 14.8 93385]
[24.7 23.5 11537]
[-79.4 21.7 167808]
[82.9 39.2 50888]
[45.9 50.5 643963]
[-114.7 49.1 769400]
[24.7 -33.4 213116]
[-90 37.6 393929]
[-121.8 40.2 36834]
[137.6 38.6 171164]
[24.7 -0.9 53699]
[0 38.1 209760]
[33.5 45 671232]
[38.8 -4.5 41952]
[-82.9 35.8 155642]
[22.9 69.4 11537]
[79.4 20 2433216]
[5.3 40.2 671232]
[44.1 38.6 1064029]
[100.6 50.5 20137]
[-105.9 42.3 19969]
[51.2 41.2 10614]
[35.3 60 1583688]
[-100.6 39.7 34023]
[28.2 18.2 53699]
[97.1 18.2 411381]
[86.5 43.6 65026]
[-75.9 41.2 284267]
[123.5 40.2 2307360]
[112.9 1 65026]
[28.2 13 126276]
[35.3 38.1 1887840]
[15.9 -21.8 50888]
[77.6 40.2 328610]
[14.1 -0.9 53699]
[125.3 38.6 2663952]
[-111.2 37.1 81135]
[10.6 45 1623542]
[-77.6 39.7 364563]
[97.1 34.3 53699]
[105.9 39.7 391118]
[-118.2 38.1 56761]
[102.4 39.2 11537]
[22.9 66.8 46147]
[45.9 25.4 234931]
[72.4 61.7 53699]
[-111.2 39.7 28402]
[10.6 61.7 596683]
[84.7 37.1 25591]
[31.8 20 132988]
[22.9 -31.8 25591]
[-70.6 -21.8 40274]
[42.4 38.1 1218706]
[10.6 49.1 646061]
[-52.9 -20.1 679497]
[40.6 45 704794]
[56.5 27.4 30205]
[8.8 47.8 2265408]
[109.4 35.8 2001110]
[-121.8 42.3 1107365]
[-102.4 40.7 39729]
[-1.8 42.3 1470418]
[77.6 43.6 53699]
[-67.1 -28.5 53699]
[-82.9 31.2 773175]
[112.9 37.6 3335184]
[-52.9 -16.7 223604]
[142.9 62.6 53699]
[54.7 67.7 53699]
[72.4 66 53699]
[107.6 35.8 2154235]
[56.5 34.3 234931]
[86.5 31.2 1435178]
[30 38.1 323030]
[107.6 60.9 53699]
[-70.6 -26.8 53699]
[30 -0.9 1678080]
[22.9 60.9 56635]
[77.6 34.3 1609279]
[42.4 47.8 234931]
[40.6 46.4 589426]
[-10.6 32.7 146832]
[26.5 13 53699]
[130.6 49.1 53699]
[-72.4 45 19969]
[33.5 39.2 966994]
[12.4 -11.7 102782]
[40.6 20 41952]
[19.4 41.2 1678080]
[68.8 40.2 110334]
[90 40.7 132988]
[-70.6 47.8 17158]
[-68.8 -33.4 53699]
[88.2 61.7 36834]
[111.2 39.7 620890]
[68.8 25.4 869497]
[61.8 63.4 132988]
[-77.6 25.4 14683]
[58.2 60.9 234931]
[54.7 66.8 53699]
[-95.3 42.3 61669]
[-75.9 -6.3 53699]
[130.6 41.2 1609405]
[-61.8 -11.7 70731]
[97.1 39.7 19969]
[81.2 41.2 45266]
[14.1 67.7 45266]
[109.4 37.6 2573755]
[19.4 3 111592]
[-70.6 -28.5 87680]
[111.2 29.4 2894688]
[107.6 42.3 48077]
[47.6 23.5 42455]
[-102.4 37.1 240888]
[84.7 31.2 2175211]
[120 31.2 209760]
[-37.1 -4.5 671232]
[128.8 45 53699]
[-118.2 60 19969]
[-104.1 40.7 56677]
[86.5 60 189623]
[132.4 43.6 50342]
[105.9 61.7 53699]
[7.1 9.1 2412240]
[31.8 -6.3 234931]
[82.9 66 53699]
[-49.4 -8.1 53699]
[61.8 69.4 53699]
[-104.1 43.6 34023]
[-86.5 14.8 478798]
[-1.8 7.1 727867]
[-10.6 49.1 94812]
[160.6 60.9 10991]
[102.4 43.6 11537]
[-102.4 39.7 28402]
[-44.1 -11.7 140959]
[84.7 60.9 53699]
[-81.2 -0.9 1216608]
[61.8 35.8 53699]
[61.8 46.4 53699]
[116.5 3 46986]
[12.4 -0.9 67375]
[-109.4 47.8 39645]
[-68.8 -11.7 146664]
[155.3 -6.3 21396]
[35.3 -8.1 234931]
[114.7 35.8 3314208]
[86.5 25.4 3188352]
[-67.1 41.2 46986]
[82.9 43.6 48077]
[118.2 31.2 1986427]
[54.7 63.4 121661]
[100.6 18.2 1300512]
[107.6 41.2 19969]
[-45.9 -4.5 142217]
[105.9 41.2 11537]
[8.8 45 2034672]
[65.3 67.7 53699]
[95.3 39.2 39645]
[95.3 38.6 14348]
[-1.8 37.1 505102]
[-38.8 -6.3 289469]
[-70.6 9.1 53699]
[-160.6 25.4 14683]
[12.4 3 50888]
[-100.6 37.1 22780]
[-68.8 -8.1 62383]
[-72.4 40.2 1772472]
[-74.1 -13.4 234931]
[-47.6 -0.9 53699]
[-86.5 13 65445]
[-70.6 13 534888]
[104.1 64.3 17158]
[118.2 38.6 167808]
[123.5 -8.1 209760]
[93.5 34.3 41910]
[90 45 22780]
[19.4 -11.7 11537]
[-70.6 -39.2 53699]
[90 60 17158]
[107.6 13 14683]
[-120 49.1 17158]
[-68.8 42.3 61669]
[150 -30.1 45266]
[26.5 11.2 164871]
[90 25.4 1908816]
[33.5 7.1 50888]
[125.3 49.1 53699]
[52.9 62.6 234931]
[12.4 40.7 503424]
[-116.5 42.3 65193]
[86.5 66 10991]
[31.8 60 234931]
[130.6 -11.7 20598]
[-70.6 -23.4 40274]
[-109.4 41.2 56761]
[86.5 50.5 234931]
[15.9 60 18039]
[-1.8 16.5 650256]
[-102.4 23.5 1050898]
[91.8 40.2 17158]
[-79.4 38.1 285106]
[8.8 64.3 42455]
[22.9 -4.5 742131]
[22.9 40.7 1426368]
[79.4 29.4 2663952]
[74.1 20 2684928]
[-77.6 -2.7 53699]
[-95.3 21.7 251712]
[142.9 46.4 10068]
[151.8 -26.8 641950]
[-74.1 9.1 922944]
[-67.1 -9.9 11537]
[-1.8 41.2 605367]
[-58.2 -25.1 467597]
[-5.3 35.8 250873]
[-104.1 32.7 25591]
[-63.5 41.2 112851]
[19.4 46.4 1761984]
[-146.5 66 39645]
[-10.6 35.8 98587]
[141.2 -37.8 13425]
[28.2 -21.8 303942]
[-49.4 -20.1 2684928]
[33.5 5 129632]
[56.5 62.6 234931]
[-70.6 40.2 167808]
[44.1 7.1 132988]
[-3.5 18.2 296433]
[111.2 -0.9 166969]
[84.7 61.7 53699]
[-51.2 -6.3 53699]
[104.1 16.5 773301]
[114.7 -0.9 424806]
[35.3 -6.3 262200]
[15.9 62.6 419940]
[24.7 66.8 47154]
[125.3 9.1 685915]
[14.1 -4.5 627602]
[49.4 -11.7 29366]
[-90 40.7 210180]
[81.2 25.4 2559072]
[-70.6 -35.1 393929]
[22.9 -28.5 75514]
[8.8 62.6 96196]
[-3.5 38.6 425813]
[54.7 41.2 53699]
[-56.5 -25.1 263459]
[-58.2 -35.1 602011]
[104.1 21.7 643544]
[-74.1 66 10446]
[56.5 31.2 194238]
[-107.6 35.8 384952]
[12.4 -8.1 289553]
[-84.7 39.2 782405]
[10.6 46.4 2280091]
[-104.1 45 59488]
[42.4 11.2 182911]
[107.6 50.5 36918]
[-100.6 35.8 120654]
[37.1 -6.3 141588]
[-123.5 49.1 31212]
[141.2 39.2 461472]
[-7.1 29.4 11537]
[-121.8 40.7 137686]
[15.9 7.1 87680]
[-8.8 47.8 302054]
[104.1 25.4 1245974]
[24.7 -28.5 249405]
[19.4 66.8 59488]
[24.7 67.7 19969]
[33.5 9.1 42455]
[84.7 23.5 2622000]
[-98.8 46.4 27311]
[12.4 41.2 1174656]
[-81.2 32.7 574742]
[12.4 -16.7 19969]
[-72.4 -40.5 95651]
[15.9 9.1 121661]
[47.6 -18.4 341909]
[-74.1 14.8 14683]
[31.8 13 65026]
[-105.9 27.4 227925]
[26.5 38.1 98587]
[114.7 37.6 4153248]
[63.5 34.3 234931]
[-70.6 14.8 47406]
[47.6 25.4 48077]
[-109.4 34.3 50972]
[15.9 18.2 42455]
[98.8 43.6 19969]
[127.1 38.1 1137990]
[-77.6 -6.3 427910]
[-123.5 39.7 82058]
[-100.6 42.3 65193]
[-52.9 -21.8 1007393]
[56.5 68.5 53699]
[95.3 35.8 53699]
[125.3 -8.1 58733]
[-86.5 38.1 365402]
[67.1 40.2 121661]
[148.2 -8.1 16781]
[-82.9 40.7 32723]
[-77.6 9.1 194028]
[-79.4 37.1 175359]
[37.1 68.5 53699]
[-98.8 34.3 479637]
[-100.6 25.4 146119]
[67.1 69.4 16781]
[-61.8 -0.9 218570]
[178.2 -15 182491]
[90 47.8 22780]
[-100.6 43.6 45266]
[-67.1 -26.8 142217]
[31.8 21.7 53699]
[61.8 50.5 316738]
[44.1 11.2 200950]
[82.9 27.4 2538096]
[79.4 63.4 53699]
[98.8 38.6 72157]
[52.9 64.3 53699]
[10.6 41.2 2055648]
[77.6 32.7 4048368]
[84.7 46.4 212277]
[24.7 -13.4 39645]
[52.9 60 1164168]
[-65.3 11.2 313381]
[104.1 11.2 167808]
[114.7 38.6 3838608]
[77.6 72 38554]
[-40.6 -8.1 129632]
[-8.8 31.2 17158]
[-90 40.2 616275]
[-60 -28.5 96909]
[-54.7 -31.8 110334]
[123.5 13 455179]
[28.2 60.9 234931]
[1.8 21.7 11537]
[-84.7 40.7 158159]
[28.2 39.2 1594176]
[105.9 63.4 53699]
[120 25.4 167808]
[-130.6 49.1 14431]
[-104.1 40.2 25591]
[-51.2 -9.9 34023]
[28.2 67.7 34023]
[-21.2 77.3 12711]
[56.5 45 53699]
[90 27.4 3754704]
[-104.1 47.8 22780]
[-91.8 40.2 328065]
[125.3 42.3 2559072]
[79.4 61.7 46986]
[79.4 16.5 1342464]
[30 11.2 126276]
[-93.5 42.3 135337]
[38.8 38.6 1317293]
[107.6 -0.9 14683]
[-63.5 -36.5 562157]
[174.7 -36.5 69347]
[44.1 29.4 144315]
[77.6 21.7 2684928]
[74.1 38.6 36834]
[107.6 43.6 42455]
[44.1 21.7 62383]
[1.8 39.7 1027824]
[-60 1 17158]
[141.2 62.6 53699]
[84.7 29.4 4363008]
[7.1 14.8 2684928]
[93.5 20 811771]
[102.4 34.3 2014535]
[-68.8 -15 234931]
[-52.9 -13.4 11537]
[-68.8 -16.7 155642]
[26.5 -9.9 220248]
[-72.4 9.1 340650]
[24.7 -31.8 110334]
[-111.2 42.3 42078]
[-7.1 39.7 388056]
[105.9 47.8 30205]
[118.2 -4.5 14683]
[-88.2 20 14683]
[-100.6 21.7 1125572]
[14.1 13 1136899]
[123.5 39.7 1686470]
[17.6 -4.5 398544]
[-102.4 -55.5 13257]
[38.8 63.4 53699]
[-42.4 -2.7 194238]
[-7.1 7.1 213955]
[-74.1 -37.8 88099]
[60 38.6 53699]
[-102.4 37.6 96280]
[31.8 -4.5 234931]
[-79.4 37.6 753458]
[24.7 -30.1 50888]
[-104.1 25.4 154635]
[56.5 61.7 234931]
[24.7 37.6 377568]
[67.1 67.7 50342]
[35.3 68.5 53699]
[-49.4 -2.7 53699]
[-58.2 -4.5 42455]
[-100.6 23.5 857918]
[-104.1 39.2 92462]
[79.4 40.7 153544]
[14.1 45 1552224]
[74.1 62.6 53699]
[82.9 32.7 295510]
[104.1 60 53699]
[135.9 45 40274]
[-40.6 -9.9 200950]
[-60 43.6 10614]
[56.5 49.1 234931]
[30 18.2 53699]
[-40.6 -4.5 216892]
[38.8 64.3 53699]
[49.4 43.6 53699]
[17.6 -0.9 53699]
[24.7 -4.5 200950]
[-67.1 -18.4 53699]
[109.4 25.4 2915664]
[-86.5 45 14348]
[-112.9 41.2 42623]
[22.9 42.3 1300512]
[88.2 50.5 132988]
[45.9 5 39267]
[17.6 66.8 14348]
[-5.3 38.6 453082]
[19.4 34.3 68256]
[10.6 13 895675]
[54.7 39.2 53699]
[-74.1 42.3 25675]
[44.1 66 53699]
[52.9 38.1 472086]
[37.1 41.2 323030]
[30 -9.9 99007]
[8.8 60.9 125856]
[70.6 23.5 671232]
[38.8 29.4 53699]
[-58.2 -2.7 28402]
[17.6 46.4 1524955]
[74.1 67.7 53699]
[-114.7 46.4 470827]
[125.3 11.2 797088]
[-97.1 38.1 123716]
[51.2 47.8 371275]
[45.9 7.1 87680]
[114.7 50.5 53699]
[171.2 -39.2 10068]
[42.4 64.3 53699]
[12.4 -13.4 87218]
[-82.9 25.4 308347]
[14.1 64.3 25591]
[81.2 67.7 53699]
[26.5 7.1 73542]
[-52.9 66.8 10991]
[114.7 39.2 2238139]
[105.9 50.5 53699]
[12.4 66.8 36834]
[-97.1 41.2 53699]
[-81.2 37.1 503004]
[63.5 47.8 53699]
[-90 38.1 310025]
[-56.5 43.6 36834]
[1.8 40.2 1218706]
[5.3 14.8 671232]
[-120 41.2 92378]
[-52.9 -26.8 316738]
[98.8 18.2 1415880]
[45.9 39.7 1497686]
[42.4 62.6 53699]
[-56.5 -31.8 53699]
[42.4 16.5 1345820]
[17.6 62.6 244580]
[72.4 45 212277]
[40.6 5 65026]
[-60 -25.1 36834]
[33.5 34.3 44721]
[17.6 50.5 209760]
[120 3 73416]
[-109.4 38.6 39183]
[-88.2 35.8 87680]
[35.3 1 1443149]
[-100.6 41.2 19969]
[45.9 9.1 65026]
[84.7 41.2 76437]
[-111.2 43.6 31212]
[30 47.8 1803936]
[33.5 -13.4 1488457]
[77.6 25.4 2433216]
[107.6 64.3 53699]
[-88.2 23.5 100265]
[24.7 42.3 797088]
[22.9 49.1 1426368]
[97.1 25.4 211438]
[-72.4 5 39645]
[19.4 -9.9 48077]
[35.3 16.5 144315]
[-8.8 32.7 42539]
[40.6 25.4 234931]
[-10.6 46.4 29912]
[116.5 46.4 53699]
[132.4 41.2 373373]
[151.8 -28.5 77611]
[35.3 -0.9 391077]
[98.8 32.7 44721]
[56.5 32.7 234931]
[19.4 -25.1 36834]
[10.6 11.2 650256]
[40.6 23.5 1235486]
[-81.2 3 14683]
[22.9 -13.4 76353]
[63.5 41.2 53699]
[75.9 39.2 217773]
[47.6 63.4 65026]
[-74.1 -4.5 45266]
[35.3 39.2 562157]
[42.4 45 220248]
[165.9 -15 14683]
[111.2 76.4 10446]
[37.1 61.7 89484]
[118.2 60 53699]
[114.7 61.7 53699]
[54.7 39.7 53699]
[58.2 42.3 53699]
[-72.4 -8.1 36834]
[98.8 5 72409]
[24.7 -23.4 422289]
[47.6 66.8 53699]
[97.1 3 209760]
[52.9 71.1 17872]
[130.6 45 53699]
[-70.6 -11.7 42623]
[56.5 69.4 17326]
[90 46.4 53699]
[49.4 63.4 53699]
[-56.5 -18.4 42455]
[-105.9 35.8 44805]
[-95.3 68.5 10446]
[-79.4 47.8 10530]
[-56.5 -4.5 53699]
[19.4 65.1 63348]
[-93.5 34.3 204013]
[77.6 39.2 157530]
[-97.1 45 67459]
[75.9 49.1 282756]
[-105.9 37.1 25591]
[37.1 49.1 922944]
[97.1 29.4 780265]
[114.7 31.2 2307360]
[82.9 49.1 234931]
[42.4 23.5 262200]
[135.9 40.7 14683]
[98.8 39.7 17158]
[17.6 42.3 1552224]
[-44.1 -8.1 76353]
[38.8 37.1 107607]
[142.9 63.4 53699]
[86.5 29.4 4048368]
[109.4 63.4 31212]
[44.1 -15 23493]
[8.8 29.4 11537]
[-3.5 37.6 503424]
[8.8 1 29031]
[-81.2 43.6 22780]
[24.7 40.7 1489296]
[-72.4 21.7 2028379]
[63.5 70.2 10068]
[51.2 72 21773]
[38.8 -6.3 30457]
[45.9 47.8 234931]
[125.3 47.8 53699]
[112.9 -0.9 144315]
[31.8 25.4 17158]
[33.5 43.6 2055648]
[51.2 61.7 262200]
[70.6 35.8 2684928]
[97.1 42.3 11537]
[-44.1 -0.9 47406]
[90 39.7 42455]
[-116.5 75.6 13257]
[38.8 62.6 53699]
[21.2 -4.5 289469]
[-8.8 49.1 386504]
[31.8 66.8 50888]
[-118.2 37.1 2118576]
[146.5 -4.5 13425]
[81.2 9.1 224443]
[1.8 41.2 453082]
[77.6 71.1 50342]
[40.6 40.7 534888]
[-107.6 70.2 11537]
[68.8 38.1 1191437]
[74.1 49.1 137603]
[15.9 14.8 53699]
[33.5 18.2 178296]
[-121.8 66 14348]
[56.5 65.1 53699]
[-79.4 40.7 699759]
[28.2 9.1 189623]
[49.4 61.7 234931]
[65.3 65.1 53699]
[30 69.4 53699]
[151.8 -30.1 64187]
[-109.4 38.1 45266]
[132.4 1 20137]
[19.4 42.3 1657104]
[-72.4 -2.7 44175]
[-67.1 -40.5 53699]
[-111.2 34.3 75430]
[114.7 40.2 65110]
[-74.1 40.7 180100]
[33.5 11.2 234638]
[-164.1 69.4 10446]
[-88.2 39.7 982096]
[127.1 72.9 11537]
[-3.5 60.9 239126]
[-54.7 42.3 62634]
[-79.4 -8.1 115368]
[75.9 35.8 1489002]
[70.6 37.6 1017756]
[-52.9 71.1 11075]
[-109.4 27.4 14683]
[98.8 46.4 13257]
[0 39.2 41952]
[111.2 46.4 53699]
[58.2 23.5 10068]
[58.2 37.1 234931]
[109.4 42.3 11537]
[-10.6 14.8 155642]
[37.1 69.4 16781]
[-93.5 40.7 719477]
[121.8 20 503424]
[21.2 61.7 44050]
[67.1 38.1 1136899]
[-164.1 68.5 10446]
[74.1 21.7 2684928]
[40.6 38.6 994262]
[40.6 1 129632]
[67.1 29.4 1886539]
[-100.6 38.1 31212]
[17.6 -31.8 67543]
[75.9 64.3 53699]
[68.8 27.4 622987]
[91.8 39.2 14348]
[-72.4 39.7 1048800]
[26.5 45 671232]
[26.5 18.2 36834]
[44.1 43.6 223604]
[-79.4 41.2 53699]
[-60 -33.4 868406]
[-56.5 45 26849]
[37.1 29.4 50888]
[12.4 5 65026]
[-54.7 1 53699]
[60 61.7 234931]
[70.6 25.4 2412240]
[30 -26.8 811352]
[22.9 -9.9 58859]
[171.2 -41.9 62005]
[127.1 40.7 1602566]
[8.8 34.3 11537]
[22.9 62.6 83484]
[-70.6 -16.7 313381]
[81.2 46.4 155642]
[-54.7 -0.9 46986]
[-72.4 -37.8 200950]
[38.8 32.7 48077]
[-105.9 37.6 51056]
[112.9 3 129632]
[15.9 -20.1 11537]
[-47.6 -2.7 76353]
[17.6 66 39645]
[45.9 -16.7 121661]
[28.2 66.8 50888]
[82.9 42.3 87680]
[-56.5 7.1 25675]
[19.4 -8.1 53699]
[44.1 27.4 234931]
[84.7 63.4 39645]
[30 38.6 671232]
[61.8 29.4 176198]
[-65.3 -35.1 25591]
[-79.4 39.2 628860]
[68.8 49.1 110334]
[74.1 65.1 53699]
[45.9 38.6 922944]
[63.5 38.1 99007]
[-56.5 -33.4 59572]
[-5.3 16.5 431267]
[15.9 -11.7 371275]
[-77.6 -0.9 17158]
[51.2 66.8 50342]
[44.1 -21.8 76353]
[84.7 66.8 14348]
[97.1 11.2 125856]
[37.1 13 2280091]
[8.8 -0.9 30205]
[-67.1 -39.2 53699]
[90 43.6 45266]
[65.3 40.2 129632]
[109.4 37.1 2559072]
[65.3 60 87680]
[-118.2 63.4 11537]
[-56.5 42.3 11159]
[-102.4 20 18039]
[12.4 43.6 1860571]
[10.6 47.8 1761984]
[148.2 -9.9 10068]
[-120 45 121661]
[-10.6 20 42455]
[98.8 42.3 22780]
[75.9 32.7 3419088]
[-116.5 40.2 65990]
[-77.6 1 30751]
[-45.9 -21.8 1204022]
[26.5 38.6 1552769]
[-70.6 7.1 11537]
[45.9 35.8 547599]
[151.8 -25.1 192937]
[40.6 9.1 73542]
[10.6 14.8 371275]
[74.1 40.7 155642]
[-7.1 37.1 964602]
[-37.1 -6.3 485804]
[-67.1 -37.8 36834]
[-93.5 37.6 271429]
[31.8 38.6 643963]
[-98.8 39.7 82058]
[28.2 -26.8 289007]
[21.2 45 2307360]
[15.9 38.6 503424]
[167.6 69.4 10446]
[77.6 70.2 53699]
[-74.1 40.2 887830]
[68.8 32.7 1343303]
[52.9 20 36918]
[-144.7 66 22780]
[42.4 39.7 1011043]
[120 -0.9 205565]
[-120 37.1 182491]
[8.8 14.8 2307360]
[77.6 23.5 2684928]
[47.6 39.7 673330]
[47.6 69.4 20137]
[-130.6 60 11537]
[74.1 18.2 2684928]
[146.5 -33.4 31212]
[95.3 31.2 878307]
[22.9 -0.9 53699]
[121.8 42.3 677525]
[30 70.2 26849]
[54.7 46.4 212277]
[100.6 38.6 573861]
[35.3 47.8 344006]
[-98.8 41.2 45266]
[82.9 65.1 53699]
[-65.3 -11.7 10991]
[21.2 66 29366]
[35.3 46.4 922944]
[-72.4 42.3 257166]
[-111.2 38.6 14348]
[121.8 46.4 36834]
[68.8 35.8 551669]
[77.6 68.5 44721]
[-5.3 11.2 302054]
[112.9 46.4 53699]
[-49.4 -28.5 167808]
[49.4 64.3 53699]
[19.4 45 2768832]
[-90 75.6 10446]
[72.4 67.7 27940]
[15.9 60.9 68801]
[144.7 -40.5 21773]
[61.8 45 53699]
[98.8 60.9 50342]
[135.9 50.5 10614]
[141.2 45 26849]
[84.7 49.1 234931]
[102.4 42.3 48077]
[10.6 65.1 272059]
[31.8 -18.4 677525]
[51.2 32.7 234931]
[130.6 46.4 53699]
[-3.5 39.7 248859]
[91.8 32.7 65110]
[105.9 37.6 2684928]
[60 47.8 424554]
[26.5 -4.5 65026]
[-84.7 45 19969]
[33.5 66 43630]
[-105.9 38.1 39645]
[65.3 68.5 53699]
[42.4 65.1 53699]
[-67.1 -35.1 42455]
[30 -11.7 53699]
[-82.9 11.2 401061]
[42.4 27.4 200950]
[107.6 37.1 2507891]
[65.3 45 53699]
[42.4 42.3 371275]
[12.4 60.9 414486]
[-109.4 75.6 16613]
[19.4 -31.8 36918]
[-121.8 46.4 34023]
[44.1 9.1 53699]
[-5.3 50.5 757234]
[58.2 40.2 46986]
[30 -30.1 335616]
[67.1 64.3 53699]
[-111.2 40.7 25675]
[21.2 69.4 11537]
[-63.5 -8.1 50888]
[44.1 60 1174656]
[146.5 -40.5 30751]
[-104.1 23.5 279400]
[142.9 -35.1 39645]
[21.2 67.7 17158]
[102.4 41.2 48077]
[95.3 60.9 11537]
[-58.2 -15 65026]
[75.9 14.8 2663952]
[37.1 31.2 53699]
[22.9 5 65026]
[15.9 42.3 1524955]
[-116.5 46.4 17158]
[-120 60 19969]
[-61.8 -23.4 28402]
[-56.5 -30.1 144315]
[-100.6 27.4 96196]
[-3.5 11.2 156900]
[-90 39.7 435881]
[-7.1 23.5 31212]
[22.9 35.8 30205]
[14.1 -13.4 234931]
[137.6 -2.7 53699]
[-74.1 41.2 1061092]
[67.1 68.5 53699]
[146.5 -41.9 16319]
[-3.5 43.6 769819]
[28.2 45 1048800]
[52.9 39.7 12250]
[105.9 23.5 1287926]
[132.4 42.3 1251428]
[100.6 16.5 1528311]
[141.2 -36.5 45266]
[28.2 11.2 344006]
[22.9 61.7 120822]
[91.8 31.2 901507]
[-8.8 34.3 819323]
[60 50.5 671232]
[37.1 60 2307360]
[104.1 49.1 53699]
[37.1 3 42455]
[-109.4 62.6 11537]
[19.4 38.6 14683]
[1.8 38.1 943920]
[132.4 45 53699]
[33.5 40.7 503424]
[116.5 -8.1 86002]
[24.7 45 1300512]
[26.5 -25.1 1142605]
[-88.2 37.1 342748]
[-98.8 37.6 192140]
[135.9 -2.7 42455]
[141.2 -35.1 11537]
[74.1 43.6 53866]
[144.7 63.4 53699]
[37.1 39.7 545376]
[-5.3 18.2 138693]
[102.4 40.7 22780]
[82.9 62.6 53699]
[-107.6 27.4 565051]
[-91.8 37.6 155642]
[30 61.7 480350]
[77.6 38.6 244161]
[-111.2 29.4 13425]
[37.1 38.1 2181504]
[-68.8 -37.8 53699]
[-42.4 -6.3 76353]
[35.3 -18.4 14683]
[-7.1 34.3 182911]
[56.5 39.7 53699]
[-47.6 -13.4 189623]
[54.7 49.1 234931]
[35.3 -21.8 14683]
[-81.2 39.7 1692763]
[8.8 13 922944]
[47.6 -11.7 44050]
[10.6 -2.7 75514]
[109.4 34.3 2181504]
[118.2 46.4 53699]
[17.6 -8.1 53699]
[24.7 -25.1 174478]
[116.5 61.7 53699]
[-8.8 37.1 497131]
[1.8 40.7 398544]
[38.8 60.9 853723]
[31.8 14.8 305956]
[102.4 49.1 37463]
[38.8 -8.1 23493]
[-100.6 40.2 25591]
[-70.6 46.4 42455]
[61.8 62.6 234931]
[141.2 38.6 167808]
[-123.5 41.2 599326]
[70.6 34.3 3209328]
[-3.5 9.1 1038312]
[35.3 -11.7 53699]
[-68.8 66.8 10991]
[74.1 23.5 2684928]
[-107.6 47.8 61753]
[1.8 46.4 671232]
[102.4 47.8 50342]
[60 64.3 53699]
[60 49.1 1120118]
[-118.2 50.5 25591]
[112.9 -21.8 10530]
[137.6 60.9 50342]
[139.4 -8.1 10068]
[114.7 1 84869]
[1.8 13 234931]
[148.2 -25.1 25591]
[81.2 60 144315]
[70.6 64.3 53699]
[19.4 -33.4 82226]
[70.6 49.1 405256]
[-72.4 46.4 19969]
[14.1 46.4 2055648]
[0 16.5 223604]
[21.2 43.6 2055648]
[72.4 46.4 87680]
[17.6 14.8 53699]
[65.3 64.3 53699]
[8.8 49.1 1234647]
[-102.4 45 53699]
[51.2 29.4 125856]
[88.2 49.1 155642]
[102.4 21.7 503844]
[-70.6 -8.1 11537]
[47.6 11.2 53699]
[-95.3 32.7 56635]
[97.1 46.4 39645]
[37.1 -11.7 99007]
[-38.8 -2.7 127954]
[-97.1 39.7 436427]
[100.6 5 1441051]
[75.9 41.2 144315]
[-14.1 14.8 220248]
[-93.5 18.2 507619]
[15.9 11.2 427910]
[33.5 -2.7 248062]
[79.4 65.1 53699]
[-65.3 -41.9 20137]
[-102.4 34.3 17158]
[79.4 41.2 53699]
[-118.2 37.6 875790]
[-49.4 -23.4 1761984]
[-12.4 21.7 11537]
[79.4 31.2 3314208]
[-61.8 -9.9 110418]
[79.4 21.7 1524955]
[15.9 -8.1 189623]
[120 45 104712]
[54.7 47.8 234931]
[14.1 7.1 76353]
[52.9 61.7 234931]
[28.2 43.6 1174656]
[31.8 39.7 1204022]
[139.4 -6.3 53699]
[58.2 64.3 53699]
[15.9 45 2433216]
[-58.2 -20.1 11537]
[-120 39.2 110418]
[86.5 74.7 11537]
[123.5 43.6 524400]
[93.5 29.4 785341]
[51.2 62.6 174940]
[24.7 -2.7 53699]
[31.8 50.5 234931]
[61.8 49.1 211438]
[146.5 -18.4 20766]
[-74.1 -0.9 39099]
[-70.6 -20.1 33562]
[-97.1 40.2 286113]
[37.1 9.1 1875254]
[98.8 37.1 31212]
[-72.4 43.6 70815]
[58.2 50.5 453082]
[44.1 -20.1 76353]
[90 32.7 76437]
[47.6 39.2 922944]
[116.5 34.3 2538096]
[7.1 40.7 1608859]
[125.3 38.1 371821]
[-68.8 9.1 41910]
[-8.8 38.1 224989]
[135.9 38.1 842942]
[-49.4 -6.3 53699]
[68.8 71.1 53699]
[-49.4 1 23493]
[86.5 49.1 234931]
[38.8 40.2 41952]
[26.5 -26.8 392671]
[7.1 11.2 1174656]
[134.1 49.1 53699]
[132.4 46.4 53699]
[97.1 49.1 53699]
[-68.8 11.2 87680]
[-68.8 5 10991]
[81.2 32.7 1114245]
[81.2 23.5 2433216]
[38.8 61.7 253390]
[-75.9 -0.9 48077]
[116.5 45 41365]
[-51.2 -16.7 234931]
[111.2 38.1 1776667]
[35.3 61.7 144315]
[21.2 7.1 87764]
[144.7 62.6 48077]
[-91.8 39.2 103621]
[72.4 20 1066839]
[-70.6 -30.1 95651]
[98.8 74.7 10991]
[28.2 42.3 2559072]
[137.6 61.7 53699]
[33.5 -23.4 146832]
[22.9 3 65026]
[63.5 42.3 28402]
[42.4 18.2 1692763]
[10.6 27.4 11537]
[77.6 67.7 53699]
[135.9 60.9 53699]
[22.9 -26.8 108865]
[-72.4 -30.1 117466]
[61.8 68.5 53699]
[-105.9 46.4 189623]
[33.5 1 1657104]
[-10.6 31.2 28402]
[74.1 70.2 53699]
[28.2 60 234931]
[82.9 66.8 50888]
[35.3 60.9 234931]
[-107.6 40.2 39645]
[77.6 39.7 59404]
[67.1 39.2 1245974]
[74.1 64.3 53699]
[-125.3 67.7 11537]
[56.5 50.5 316738]
[-86.5 35.8 198852]
[-97.1 18.2 36079]
[54.7 37.1 200950]
[35.3 69.4 46986]
[118.2 60.9 39645]
[120 -4.5 167808]
[-91.8 41.2 110334]
[-74.1 -8.1 53699]
[-81.2 -6.3 41952]
[51.2 35.8 316738]
[-77.6 7.1 207704]
[93.5 18.2 182491]
[72.4 68.5 16781]
[33.5 50.5 274786]
[153.5 -4.5 10068]
[19.4 50.5 84995]
[65.3 32.7 99007]
[-54.7 -4.5 53699]
[-45.9 -16.7 41449]
[61.8 64.3 53699]
[-1.8 47.8 2663952]
[-3.5 60 922944]
[21.2 -9.9 45266]
[45.9 34.3 1504944]
[49.4 68.5 41365]
[111.2 1 166969]
[-42.4 -21.8 59991]
[116.5 43.6 22864]
[52.9 69.4 13970]
[-65.3 -16.7 178296]
[-112.9 46.4 22780]
[-1.8 14.8 1470418]
[7.1 35.8 96196]
[132.4 37.1 1022077]
[-97.1 40.7 126276]
[45.9 20 19969]
[90 40.2 50888]
[0 20 50888]
[109.4 49.1 50888]
[-79.4 43.6 42455]
[79.4 49.1 234931]
[75.9 63.4 53699]
[49.4 14.8 20137]
[72.4 65.1 53699]
[104.1 13 1657104]
[-74.1 21.7 671232]
[68.8 23.5 167808]
[-68.8 -28.5 53699]
[38.8 31.2 53699]
[-98.8 32.7 396824]
[95.3 37.1 25591]
[14.1 65.1 104796]
[-79.4 23.5 182491]
[21.2 -33.4 65445]
[28.2 61.7 507619]
[91.8 34.3 36834]
[-90 18.2 775818]
[118.2 39.7 2154235]
[82.9 40.7 65026]
[24.7 49.1 1048800]
[84.7 35.8 45266]
[-72.4 -16.7 21396]
[91.8 27.4 1975939]
[-3.5 47.8 1514467]
[45.9 39.2 1273243]
[97.1 13 47406]
[22.9 -8.1 65026]
[-51.2 -21.8 1552224]
[-77.6 39.2 1707446]
[-54.7 -25.1 704794]
[-95.3 37.6 332679]
[79.4 35.8 25675]
[12.4 62.6 121661]
[-98.8 29.4 909477]
[42.4 37.6 872308]
[120 42.3 130177]
[65.3 66 50342]
[-112.9 49.1 150188]
[176.5 -37.8 26849]
[28.2 -9.9 126821]
[107.6 46.4 53699]
[74.1 31.2 2433216]
[-70.6 -41.9 53699]
[63.5 60.9 234931]
[128.8 50.5 50888]
[139.4 -2.7 53699]
[77.6 40.7 65026]
[98.8 23.5 623784]
[-121.8 39.2 326051]
[139.4 64.3 17158]
[141.2 -33.4 13802]
[121.8 40.7 316738]
[-58.2 5 31212]
[54.7 60.9 205565]
[35.3 32.7 34023]
[56.5 66 53699]
[58.2 47.8 344006]
[-97.1 37.1 401900]
[98.8 21.7 1174656]
[-7.1 16.5 638929]
[68.8 29.4 1378123]
[-60 -0.9 204264]
[38.8 39.7 545376]
[-67.1 42.3 65026]
[93.5 39.2 42455]
[-112.9 39.7 429337]
[-90 37.1 144315]
[19.4 14.8 53699]
[112.9 35.8 2483558]
[-40.6 -18.4 419520]
[100.6 37.1 53699]
[125.3 -2.7 44050]
[58.2 67.7 53699]
[-26.5 71.1 11075]
[-102.4 38.6 28402]
[45.9 60 983774]
[72.4 64.3 53699]
[112.9 -6.3 608304]
[-45.9 -11.7 50972]
[49.4 39.2 209760]
[44.1 49.1 234931]
[47.6 67.7 53699]
[68.8 31.2 1565649]
[0 46.4 1489296]
[-54.7 -30.1 234931]
[-5.3 14.8 734160]
[-93.5 35.8 321352]
[97.1 27.4 500194]
[14.1 69.4 43882]
[127.1 38.6 1345820]
[-40.6 -13.4 792054]
[-56.5 -13.4 51056]
[-54.7 -26.8 388056]
[-58.2 7.1 53321]
[72.4 40.7 53699]
[-5.3 37.6 880992]
[-60 -13.4 14348]
[134.1 -4.5 29366]
[5.3 64.3 70983]
[-70.6 -36.5 53699]
[121.8 39.7 2978592]
[60 41.2 10614]
[-61.8 -21.8 11537]
[-56.5 3 53699]
[28.2 46.4 1552224]
[31.8 -9.9 61753]
[-93.5 41.2 477833]
[26.5 1 110334]
[56.5 67.7 53699]
[75.9 61.7 53699]
[-123.5 39.2 70186]
[14.1 -16.7 155642]
[0 14.8 182911]
[-121.8 38.6 1329039]
[24.7 -16.7 225660]
[38.8 20 29366]
[-81.2 29.4 719896]
[134.1 37.1 470953]
[7.1 45 2601024]
[72.4 62.6 53699]
[81.2 63.4 53699]
[33.5 -9.9 232372]
[31.8 68.5 53699]
[-111.2 45 53699]
[7.1 49.1 227799]
[17.6 5 282840]
[35.3 7.1 226205]
[97.1 16.5 142637]
[-90 20 67375]
[137.6 37.6 1728422]
[75.9 38.6 535433]
[-68.8 21.7 14683]
[-5.3 39.2 650676]
[-65.3 41.2 93553]
[45.9 68.5 10068]
[51.2 66 53699]
[102.4 37.6 1432241]
[35.3 -4.5 316738]
[40.6 50.5 453082]
[68.8 50.5 166969]
[-3.5 35.8 50972]
[134.1 37.6 1294765]
[3.5 34.3 28402]
[38.8 23.5 91455]
[67.1 72 17326]
[74.1 63.4 53699]
[-56.5 -28.5 234931]
[47.6 66 53699]
[146.5 -35.1 65110]
[37.1 63.4 53699]
[-107.6 31.2 50888]
[-67.1 -25.1 153544]
[-82.9 39.2 524400]
[-40.6 -11.7 419940]
[137.6 43.6 76353]
[26.5 -23.4 131058]
[130.6 60.9 19969]
[-70.6 -31.8 1038732]
[97.1 45 28402]
[-42.4 -15 110418]
[58.2 66 53699]
[47.6 7.1 73416]
[-105.9 31.2 50972]
[-120 38.6 68004]
[-8.8 39.7 1462027]
[-90 23.5 371275]
[45.9 27.4 223604]
[7.1 47.8 2055648]
[-81.2 42.3 111215]
[123.5 16.5 14683]
[-72.4 -33.4 495034]
[-97.1 43.6 65026]
[139.4 62.6 53699]
[12.4 9.1 53699]
[79.4 40.2 296978]
[127.1 49.1 53699]
[-114.7 41.2 28402]
[45.9 45 212277]
[91.8 35.8 34023]
[112.9 34.3 3265963]
[52.9 21.7 53699]
[7.1 50.5 48664]
[22.9 1 53699]
[134.1 41.2 234931]
[52.9 27.4 40819]
[31.8 32.7 12711]
[135.9 46.4 53699]
[30 -20.1 291986]
[30 50.5 388056]
[-67.1 11.2 53699]
[81.2 39.2 189623]
[105.9 25.4 2001110]
[79.4 18.2 1342464]
[-95.3 34.3 495453]
[104.1 37.6 2307360]
[70.6 65.1 53699]
[19.4 7.1 155642]
[-8.8 21.7 28402]
[-125.3 46.4 28402]
[26.5 39.2 728958]
[116.5 60.9 53699]
[-45.9 -18.4 317996]
[37.1 37.1 1082362]
[135.9 -33.4 11705]
[-51.2 -28.5 205565]
[35.3 64.3 41365]
[102.4 -0.9 110502]
[58.2 41.2 16781]
[40.6 35.8 45266]
[42.4 60.9 578938]
[169.4 -41.9 17788]
[-58.2 45 34107]
[-1.8 39.2 998458]
[21.2 40.7 2280091]
[30 -13.4 144315]
[-68.8 -21.8 53699]
[116.5 47.8 53699]
[56.5 60.9 234931]
[-35.3 -4.5 209760]
[0 45 853723]
[45.9 32.7 708234]
[-67.1 21.7 671232]
[7.1 64.3 59488]
[-52.9 -25.1 496292]
[60 60 344006]
[26.5 61.7 371821]
[132.4 60 53699]
[26.5 63.4 56048]
[125.3 72.9 10991]
[-58.2 -13.4 65193]
[123.5 41.2 1694861]
[8.8 40.2 29366]
[-86.5 40.7 131436]
[24.7 64.3 104167]
[142.9 40.2 797088]
[5.3 42.3 1120118]
[-65.3 -31.8 200950]
[105.9 27.4 2154235]
[70.6 47.8 53699]
[5.3 46.4 2663952]
[60 34.3 121661]
[-44.1 -13.4 103160]
[12.4 60 345265]
[15.9 13 178296]
[42.4 21.7 223604]
[44.1 46.4 234931]
[-75.9 -13.4 205565]
[79.4 60.9 53699]
[12.4 65.1 14348]
[-105.9 34.3 11537]
[12.4 46.4 2154235]
[70.6 40.7 53699]
[82.9 37.1 53699]
[-100.6 40.7 14348]
[102.4 -4.5 41952]
[-111.2 32.7 104796]
[-65.3 43.6 26849]
[24.7 16.5 124555]
[26.5 39.7 928398]
[61.8 37.6 121661]
[74.1 66 53699]
[79.4 60 178296]
[-116.5 49.1 31296]
[49.4 65.1 53699]
[95.3 47.8 53699]
[-5.3 34.3 121199]
[-74.1 5 103621]
[-79.4 -0.9 818316]
[54.7 72 24584]
[-105.9 39.7 101901]
[141.2 -2.7 50342]
[-77.6 3 541181]
[81.2 45 53699]
[-38.8 -8.1 317996]
[-120 43.6 45266]
[22.9 -33.4 13425]
[35.3 21.7 28402]
[24.7 41.2 1929792]
[63.5 67.7 53699]
[-82.9 13 14683]
[132.4 40.2 117466]
[88.2 31.2 1106820]
[72.4 38.1 98545]
[104.1 38.1 1471676]
[35.3 11.2 786600]
[45.9 65.1 53699]
[72.4 50.5 220248]
[137.6 47.8 53699]
[-1.8 21.7 17158]
[65.3 60.9 76353]
[82.9 68.5 14348]
[-75.9 -2.7 53699]
[67.1 47.8 53699]
[75.9 45 155642]
[-95.3 38.1 205565]
[118.2 37.1 3377136]
[54.7 40.2 53699]
[28.2 -20.1 104712]
[-3.5 14.8 483707]
[22.9 -15 72996]
[-68.8 14.8 14683]
[-102.4 47.8 19969]
[58.2 46.4 208921]
[56.5 40.2 53699]
[105.9 39.2 387930]
[139.4 38.1 1845888]
[116.5 5 33562]
[68.8 43.6 62383]
[63.5 46.4 53699]
[130.6 -6.3 14683]
[-86.5 43.6 29031]
[112.9 29.4 2433216]
[14.1 -8.1 195329]
[104.1 27.4 1524955]
[30 20 53699]
[-52.9 -28.5 234931]
[10.6 37.6 335616]
[93.5 39.7 19969]
[-144.7 66.8 25591]
[-51.2 -11.7 59488]
[-67.1 65.1 10991]
[104.1 45 39645]
[86.5 62.6 31212]
[121.8 -8.1 167808]
[37.1 16.5 469862]
[-3.5 50.5 574868]
[-107.6 41.2 31296]
[37.1 -2.7 1075649]
[30 62.6 602011]
[22.9 60 1147387]
[127.1 41.2 1552224]
[-93.5 70.2 10991]
[31.8 -15 99007]
[30 -28.5 731056]
[-60 -35.1 671232]
[104.1 29.4 2559072]
[45.9 21.7 19969]
[77.6 66 53699]
[-56.5 -21.8 80967]
[10.6 63.4 146203]
[144.7 64.3 11537]
[-123.5 43.6 252929]
[-7.1 21.7 42455]
[14.1 50.5 14683]
[58.2 69.4 17326]
[-82.9 40.2 987131]
[75.9 34.3 2999568]
[3.5 9.1 1866864]
[79.4 27.4 2433216]
[102.4 60 47532]
[112.9 5 191427]
[54.7 38.1 332470]
[77.6 20 1931890]
[38.8 -2.7 241224]
[121.8 -4.5 56635]
[118.2 38.1 2915664]
[81.2 62.6 53699]
[-44.1 -20.1 234638]
[37.1 39.2 482448]
[40.6 16.5 111592]
[81.2 38.1 53699]
[-114.7 42.3 62299]
[-97.1 20 291273]
[12.4 11.2 603689]
[-125.3 45 53782]
[-65.3 3 11537]
[17.6 39.2 377568]
[42.4 -20.1 13425]
[-81.2 25.4 448886]
[37.1 -9.9 427910]
[-72.4 -41.9 84324]
[93.5 40.7 39645]
[28.2 70.2 27856]
[74.1 66.8 53699]
[102.4 63.4 11537]
[19.4 -0.9 53699]
[-63.5 -11.7 17158]
[93.5 21.7 1092850]
[-8.8 35.8 1959704]
[134.1 -2.7 30205]
[-17.6 14.8 74675]
[24.7 -8.1 205565]
[35.3 34.3 133869]
[30 -25.1 472925]
[-1.8 13 980418]
[21.2 3 119563]
[-63.5 -20.1 48077]
[112.9 60.9 53699]
[7.1 43.6 2559072]
[-44.1 -4.5 189623]
[74.1 35.8 2636683]
[47.6 37.6 1426368]
[93.5 46.4 53699]
[128.8 -2.7 73416]
[15.9 50.5 14683]
[19.4 13 65026]
[-91.8 18.2 1381899]
[-15.9 20 69640]
[123.5 50.5 53699]
[28.2 -6.3 95651]
[114.7 49.1 53699]
[-72.4 -50.1 11537]
[-121.8 41.2 89106]
[33.5 14.8 109327]
[14.1 -9.9 209466]
[-40.6 -15 194238]
[14.1 -11.7 425813]
[97.1 20 706598]
[-61.8 -37.8 335616]
[98.8 1 490838]
[37.1 50.5 2559072]
[31.8 66 53699]
[123.5 39.2 1531248]
[61.8 65.1 53699]
[-107.6 37.6 385497]
[8.8 41.2 2831760]
[49.4 45 53699]
[-86.5 66.8 11621]
[107.6 3 83904]
[-70.6 -25.1 53699]
[7.1 37.6 677525]
[60 70.2 18417]
[35.3 -13.4 761429]
[97.1 31.2 57852]
[-68.8 -39.2 53699]
[105.9 60 53699]
[10.6 7.1 649795]
[24.7 46.4 797088]
[60 65.1 53699]
[0 40.7 885187]
[102.4 29.4 2181504]
[-74.1 -9.9 106978]
[75.9 39.7 50888]
[-77.6 38.6 559766]
[52.9 46.4 119563]
[-15.9 13 29366]
[65.3 38.6 623407]
[-68.8 -9.9 53866]
[12.4 49.1 495034]
[22.9 39.2 183037]
[30 3 481441]
[98.8 37.6 50888]
[77.6 18.2 2684928]
[-65.3 -18.4 166969]
[-3.5 16.5 803381]
[-79.4 27.4 14683]
[84.7 60 144315]
[86.5 47.8 200950]
[-68.8 -43.3 53699]
[56.5 63.4 189623]
[107.6 32.7 2531803]
[-45.9 -13.4 25591]
[15.9 -6.3 234931]
[112.9 25.4 622987]
[-81.2 38.1 389315]
[63.5 40.7 53699]
[150 -23.4 21689]
[174.7 -37.8 76353]
[33.5 38.6 480350]
[74.1 69.4 27395]
[24.7 9.1 11537]
[139.4 43.6 13425]
[107.6 16.5 430428]
[111.2 39.2 1524955]
[45.9 37.1 469023]
[100.6 47.8 53699]
[132.4 37.6 1204022]
[-22.9 66.8 20598]
[144.7 -36.5 357012]
[14.1 43.6 1541736]
[90 34.3 47616]
[123.5 38.6 171164]
[68.8 70.2 53699]
[-5.3 29.4 14348]
[1.8 45 1650811]
[75.9 27.4 2684928]
[-12.4 20 48077]
[21.2 65.1 24752]
[90 49.1 19969]
[49.4 66 53699]
[-5.3 60.9 50342]
[-63.5 -21.8 45266]
[-67.1 -41.9 53699]
[-56.5 -15 126359]
[51.2 43.6 53699]
[79.4 71.1 53699]
[-54.7 -13.4 38722]
[107.6 38.1 480350]
[-8.8 39.2 883090]
[72.4 47.8 53699]
[90 31.2 967833]
[-79.4 1 1305966]
[30 41.2 209760]
[148.2 -26.8 25591]
[14.1 66.8 17158]
[111.2 37.6 2622000]
[58.2 62.6 234931]
[105.9 65.1 53699]
[-114.7 37.1 73164]
[5.3 45 1623542]
[33.5 35.8 315185]
[123.5 45 76353]
[1.8 9.1 1615152]
[21.2 49.1 1048800]
[121.8 45 132988]
[-77.6 -11.7 839040]
[-112.9 37.1 883929]
[3.5 20 14348]
[121.8 43.6 234931]
[28.2 -4.5 90574]
[-15.9 23.5 17158]
[105.9 16.5 52692]
[47.6 68.5 17872]
[116.5 9.1 62089]
[75.9 60 234931]
[130.6 47.8 53699]
[7.1 65.1 28653]
[63.5 63.4 53699]
[141.2 46.4 30205]
[67.1 65.1 53699]
[121.8 16.5 685915]
[100.6 39.2 25675]
[-90 60 10991]
[-70.6 42.3 80967]
[63.5 38.6 429169]
[72.4 39.7 577679]
[102.4 14.8 476826]
[109.4 29.4 2055648]
[58.2 32.7 166969]
[38.8 68.5 40274]
[31.8 41.2 167808]
[37.1 21.7 207243]
[-72.4 -31.8 643963]
[38.8 14.8 1055093]
[58.2 39.2 53699]
[1.8 42.3 1011043]
[-121.8 50.5 17158]
[88.2 34.3 17158]
[-97.1 32.7 112851]
[102.4 25.4 698627]
[1.8 11.2 1027824]
[58.2 43.6 53699]
[63.5 40.2 234931]
[45.9 60.9 453082]
[14.1 38.1 545376]
[105.9 37.1 1519753]
[104.1 41.2 17158]
[7.1 41.2 1415880]
[14.1 1 53699]
[28.2 47.8 671232]
[45.9 38.1 671232]
[-84.7 72 10991]
[-93.5 39.7 264717]
[-12.4 11.2 813869]
[82.9 40.2 358690]
[-91.8 43.6 28485]
[8.8 65.1 88938]
[-111.2 35.8 132988]
[49.4 29.4 37086]
[51.2 27.4 33562]
[65.3 40.7 53699]
[-88.2 38.1 228219]
[-116.5 37.1 554312]
[116.5 27.4 1657104]
[-58.2 -31.8 65026]
[112.9 -2.7 45854]
[10.6 40.2 700598]
[17.6 7.1 251209]
[75.9 72 24038]
[-14.1 18.2 205565]
[86.5 45 186267]
[114.7 -30.1 179429]
[37.1 -16.7 58733]
[74.1 40.2 1006428]
[116.5 40.7 95189]
[107.6 38.6 117843]
[38.8 18.2 314346]
[-1.8 40.2 843235]
[82.9 37.6 31212]
[109.4 47.8 53699]
[12.4 35.8 975887]
[56.5 29.4 62089]
[70.6 66 53699]
[42.4 1 44050]
[33.5 3 1491813]
[-97.1 42.3 99007]
[54.7 35.8 76353]
[74.1 29.4 2684928]
[-97.1 23.5 503424]
[-58.2 -9.9 19969]
[40.6 60 534888]
[105.9 13 1594176]
[118.2 61.7 34023]
[12.4 47.8 723672]
[47.6 34.3 1315195]
[-150 63.4 202083]
[38.8 1 53699]
[-82.9 37.6 690110]
[109.4 39.7 148007]
[68.8 38.6 922944]
[118.2 -2.7 629280]
[84.7 65.1 50888]
[26.5 9.1 53699]
[44.1 5 158537]
[-98.8 37.1 100895]
[-65.3 -26.8 164871]
[15.9 -28.5 17326]
[22.9 -23.4 28402]
[40.6 39.7 520205]
[40.6 21.7 480350]
[-105.9 49.1 31212]
[88.2 60.9 50888]
[63.5 65.1 50342]
[100.6 49.1 53699]
[82.9 39.7 336036]
[-104.1 29.4 254565]
[139.4 39.2 1273243]
[-61.8 -28.5 234931]
[123.5 -9.9 167808]
[118.2 32.7 2538096]
[-65.3 5 11537]
[3.5 37.6 595718]
[141.2 -4.5 53699]
[141.2 49.1 16781]
[-47.6 -16.7 38638]
[24.7 -18.4 39645]
[60 67.7 53699]
[54.7 31.2 176198]
[47.6 43.6 53699]
[44.1 45 234931]
[132.4 47.8 53699]
[135.9 43.6 53699]
[63.5 68.5 53699]
[28.2 41.2 1971744]
[21.2 34.3 48245]
[-5.3 7.1 587328]
[74.1 68.5 40819]
[-88.2 34.3 298405]
[-105.9 38.6 122542]
[79.4 42.3 50888]
[67.1 50.5 212277]
[31.8 45 868406]
[120 41.2 226121]
[-98.8 45 47070]
[-75.9 1 41910]
[-98.8 21.7 1344562]
[127.1 37.6 1120538]
[-100.6 31.2 205439]
[21.2 14.8 237448]
[40.6 11.2 904317]
[-58.2 -8.1 19969]
[24.7 60 1048800]
[132.4 50.5 53699]
[-1.8 45 209760]
[28.2 38.1 560059]
[12.4 67.7 13970]
[45.9 40.7 219409]
[-100.6 39.2 36834]
[134.1 43.6 47532]
[-65.3 42.3 58020]
[128.8 37.6 83904]
[17.6 -18.4 22780]
[-52.9 -18.4 45350]
[26.5 -31.8 871049]
[-72.4 66.8 11537]
[-90 34.3 203719]
[26.5 -16.7 72996]
[-86.5 68.5 10991]
[3.5 16.5 524400]
[-93.5 43.6 50510]
[67.1 46.4 53699]
[33.5 66.8 33562]
[-107.6 29.4 114948]
[-93.5 21.7 357012]
[107.6 60 53699]
[81.2 40.2 296433]
[26.5 5 132988]
[14.1 40.2 167808]
[-82.9 42.3 25591]
[42.4 39.2 912456]
[52.9 37.1 189623]
[79.4 45 53699]
[28.2 62.6 518107]
[82.9 35.8 39645]
[65.3 43.6 22780]
[51.2 63.4 76353]
[44.1 37.6 1015658]
[24.7 -6.3 234931]
[-58.2 -26.8 65026]
[79.4 66.8 53699]
[0 34.3 17158]
[47.6 37.1 922944]
[-65.3 -9.9 28402]
[5.3 35.8 17158]
[-114.7 32.7 27395]
[-61.8 7.1 39645]
[33.5 -8.1 373373]
[142.9 -2.7 33562]
[-58.2 -37.8 167808]
[112.9 37.1 4153248]
[47.6 -15 200950]
[-75.9 23.5 461472]
[33.5 23.5 22780]
[-54.7 7.1 36288]
[79.4 14.8 943920]
[42.4 3 172129]
[118.2 40.2 425813]
[1.8 20 11537]
[26.5 -15 248775]
[22.9 16.5 178296]
[130.6 -0.9 13970]
[-42.4 -9.9 99007]
[14.1 47.8 1052156]
[-63.5 11.2 276044]
[14.1 60.9 228219]
[-91.8 76.4 10446]
[97.1 35.8 53699]
[-134.1 61.7 14348]
[-114.7 47.8 267612]
[130.6 50.5 53699]
[-63.5 -31.8 234931]
[26.5 -20.1 121661]
[-91.8 37.1 287371]
[70.6 62.6 53699]
[-5.3 47.8 337714]
[90 41.2 42455]
[31.8 1 98587]
[-120 37.6 469862]
[91.8 46.4 53699]
[112.9 40.2 28402]
[146.5 -31.8 17158]
[74.1 38.1 280030]
[139.4 37.6 1090752]
[-88.2 -55.5 14977]
[77.6 60 234931]
[40.6 66.8 44175]
[-82.9 38.1 579483]
[95.3 18.2 167808]
[15.9 69.4 31296]
[84.7 39.7 86757]
[114.7 3 53699]
[105.9 62.6 53699]
[1.8 37.6 321352]
[-52.9 -2.7 50342]
[67.1 31.2 1753300]
[-82.9 37.1 176198]
[100.6 60.9 50342]
[91.8 47.8 11537]
[84.7 27.4 3209328]
[150 -33.4 424974]
[28.2 -25.1 601592]
[-8.8 50.5 410836]
[52.9 60.9 507619]
[-47.6 -21.8 2405947]
[100.6 46.4 25591]
[104.1 50.5 53699]
[-114.7 40.2 40903]
[120 20 826454]
[68.8 66 53699]
[30 9.1 223604]
[130.6 37.1 1386598]
[-91.8 32.7 29366]
[77.6 37.1 194238]
[135.9 -31.8 25045]
[51.2 68.5 50342]
[125.3 39.7 1552224]
[-7.1 11.2 239546]
[17.6 45 2999568]
[30 60.9 234931]
[118.2 41.2 34107]
[98.8 49.1 53699]
[17.6 64.3 14683]
[-68.8 -51.4 16781]
[88.2 40.2 127450]
[8.8 42.3 2051453]
[102.4 46.4 53699]
[70.6 68.5 53699]
[52.9 37.6 404417]
[-10.6 34.3 448886]
[-52.9 -0.9 50342]
[8.8 61.7 54663]
[28.2 39.7 1091297]
[98.8 27.4 1357693]
[-5.3 38.1 1174656]
[150 -31.8 558381]
[70.6 60 155642]
[112.9 27.4 2894688]
[95.3 46.4 53699]
[-84.7 14.8 62928]
[-107.6 39.7 14348]
[107.6 29.4 1678080]
[0 18.2 252132]
[65.3 35.8 212277]
[-1.8 39.7 404963]
[21.2 16.5 187525]
[31.8 63.4 212697]
[-60 -16.7 53699]
[54.7 65.1 53699]
[-86.5 39.2 771078]
[-14.1 21.7 39645]
[15.9 41.2 922944]
[123.5 40.7 1782960]
[70.6 50.5 223604]
[120 37.1 545376]
[-42.4 -18.4 351516]
[75.9 31.2 2894688]
[68.8 47.8 53699]
[81.2 40.7 237448]
[21.2 70.2 21689]
[109.4 23.5 839040]
[19.4 18.2 42455]
[75.9 25.4 2663952]
[31.8 39.2 2055648]
[68.8 41.2 42455]
[77.6 16.5 2684928]
[135.9 47.8 53699]
[-107.6 45 25591]
[98.8 34.3 50342]
[158.8 -8.1 14683]
[-98.8 39.2 65026]
[-132.4 60 10991]
[-102.4 39.2 31212]
[22.9 41.2 797088]
[58.2 68.5 53699]
[-67.1 -8.1 19969]
[-95.3 35.8 232834]
[26.5 -18.4 104167]
[42.4 20 1528311]
[137.6 63.4 19969]
[-75.9 -9.9 166969]
[77.6 69.4 47532]
[44.1 40.7 344006]
[150 -26.8 53699]
[37.1 34.3 66997]
[77.6 27.4 2559072]
[0 37.1 76353]
[65.3 66.8 53699]
[31.8 9.1 110334]
[24.7 35.8 13970]
[26.5 66.8 48077]
[30 -16.7 677944]
[30 66 53699]
[-74.1 -47.3 17158]
[102.4 32.7 1782960]
[-61.8 13 175066]
[-98.8 42.3 45266]
[-107.6 34.3 30751]
[22.9 7.1 42455]
[-79.4 3 303313]
[26.5 3 132988]
[8.8 11.2 925042]
[3.5 47.8 713184]
[88.2 27.4 4363008]
[24.7 39.7 1371830]
[31.8 -0.9 671232]
[21.2 -30.1 11537]
[21.2 66.8 116207]
[-7.1 39.2 388056]
[10.6 5 435881]
[8.8 18.2 31212]
[-77.6 42.3 14348]
[8.8 39.2 560059]
[97.1 21.7 214794]
[42.4 67.7 10068]
[-3.5 34.3 14348]
[74.1 47.8 53699]
[-47.6 -4.5 93385]
[-84.7 13 261361]
[63.5 39.2 507619]
[98.8 29.4 1722130]
[-61.8 41.2 44427]
[47.6 -20.1 169906]
[75.9 40.7 212277]
[54.7 64.3 53699]
[44.1 39.2 2139552]
[72.4 60.9 208921]
[-109.4 39.2 27856]
[104.1 42.3 53699]
[-157.1 23.5 14683]
[-63.5 -2.7 10446]
[-68.8 -26.8 53699]
[111.2 34.3 2531803]
[-49.4 -4.5 65026]
[-61.8 -33.4 589426]
[-47.6 -6.3 53699]
[104.1 63.4 48077]
[-10.6 9.1 427910]
[35.3 -2.7 223604]
[24.7 -26.8 134792]
[19.4 40.2 2001110]
[14.1 38.6 518107]
[44.1 65.1 53699]
[-47.6 1 10068]
[74.1 25.4 2684928]
[90 42.3 53699]
[38.8 65.1 53699]
[-118.2 45 53699]
[134.1 46.4 53699]
[-70.6 -13.4 234931]
[30 5 1667592]
[40.6 37.1 25675]
[67.1 43.6 22780]
[130.6 43.6 65026]
[-77.6 5 1023629]
[77.6 63.4 53699]
[-95.3 38.6 630958]
[30 42.3 713184]
[-91.8 34.3 184169]
[0 49.1 41952]
[75.9 40.2 205649]
[63.5 45 53699]
[-17.6 16.5 461472]
[67.1 34.3 469862]
[47.6 21.7 22780]
[75.9 29.4 2559072]
[67.1 32.7 573064]
[21.2 39.7 1245974]
[26.5 20 25591]
[35.3 14.8 276673]
[107.6 47.8 47532]
[75.9 67.7 53699]
[127.1 46.4 53699]
[-123.5 50.5 34023]
[81.2 11.2 167808]
[79.4 47.8 175485]
[51.2 25.4 39645]
[75.9 16.5 2684928]
[-86.5 39.7 704794]
[21.2 18.2 42455]
[-45.9 -8.1 50888]
[120 60 53699]
[-116.5 38.1 122626]
[-98.8 38.6 255026]
[42.4 35.8 110334]
[28.2 49.1 671232]
[120 1 182491]
[144.7 -37.8 39435]
[-63.5 -33.4 398544]
[123.5 42.3 1875254]
[98.8 16.5 1304707]
[111.2 61.7 50888]
[75.9 46.4 53699]
[90 60.9 11537]
[102.4 38.1 956506]
[-105.9 39.2 366199]
[123.5 3 98587]
[77.6 41.2 53699]
[-14.1 16.5 69640]
[121.8 -0.9 44050]
[38.8 39.2 316738]
[148.2 -36.5 19508]
[14.1 60 398544]
[139.4 61.7 50342]
[-70.6 -43.3 53699]
[38.8 40.7 671232]
[-97.1 38.6 246510]
[38.8 41.2 671232]
[26.5 49.1 671232]
[127.1 40.2 755136]
[109.4 73.8 12711]
[79.4 46.4 61669]
[31.8 62.6 434203]
[-84.7 37.6 764785]
[51.2 34.3 262200]
[-63.5 40.7 224443]
[44.1 68.5 38009]
[40.6 43.6 507619]
[35.3 -15 901968]
[82.9 20 167808]
[102.4 35.8 132988]
[102.4 38.6 709241]
[12.4 7.1 45266]
[-155.3 21.7 29366]
[-123.5 40.7 282756]
[44.1 66.8 53699]
[-61.8 -8.1 19969]
[-116.5 35.8 799018]
[68.8 60.9 53699]
[-51.2 -30.1 16319]
[45.9 31.2 31212]
[61.8 66 53699]
[-12.4 18.2 148930]
[56.5 42.3 53699]
[56.5 35.8 234931]
[-72.4 3 11537]
[21.2 -6.3 189623]
[-102.4 46.4 50888]
[-63.5 -30.1 234931]
[63.5 32.7 53699]
[-139.4 69.4 11537]
[-7.1 47.8 463570]
[98.8 7.1 272688]
[172.9 -36.5 14683]
[-1.8 11.2 151279]
[-3.5 20 10991]
[22.9 -25.1 344887]
[17.6 40.2 547474]
[-42.4 -16.7 141504]
[-52.9 -15 274324]
[60 40.7 20137]
[104.1 47.8 50342]
[-88.2 37.6 200950]
[-102.4 29.4 254019]
[-79.4 39.7 545796]
[-86.5 18.2 132694]
[52.9 38.6 21228]
[93.5 40.2 28485]
[-90 21.7 98000]
[-111.2 40.2 27940]
[42.4 60 797088]
[31.8 7.1 53699]
[137.6 42.3 72157]
[107.6 31.2 2559072]
[61.8 66.8 53699]
[68.8 46.4 53699]
[14.1 40.7 155222]
[120 21.7 377568]
[33.5 62.6 671232]
[31.8 67.7 50888]
[-105.9 40.7 36834]
[128.8 38.1 239126]
[26.5 50.5 677525]
[79.4 38.6 200950]
[-109.4 35.8 45266]
[26.5 42.3 2307360]
[-116.5 47.8 25675]
[137.6 -0.9 33562]
[44.1 38.1 1231837]
[22.9 37.6 41952]
[109.4 32.7 2433216]
[88.2 40.7 189623]
[-111.2 47.8 42455]
[33.5 61.7 344006]
[-74.1 -39.2 161515]
[104.1 34.3 4258128]
[118.2 42.3 22780]
[-148.2 63.4 92169]
[54.7 32.7 234931]
[65.3 37.6 262200]
[-68.8 41.2 121661]
[139.4 40.2 434203]
[44.1 3 186393]
[30 1 2433216]
[118.2 47.8 53699]
[116.5 40.2 221507]
[-84.7 16.5 46986]
[134.1 60.9 53699]
[26.5 -28.5 980964]
[79.4 68.5 53699]
[104.1 39.7 14348]
[111.2 60 53699]
[-1.8 35.8 34023]
[58.2 38.1 223604]
[130.6 60 28402]
[104.1 60.9 53699]
[-72.4 41.2 363850]
[139.4 39.7 239672]
[81.2 37.6 34023]
[56.5 37.1 234931]
[65.3 49.1 132988]
[-116.5 70.2 10446]
[95.3 25.4 1401197]
[28.2 -2.7 941361]
[22.9 46.4 1678080]
[127.1 43.6 198852]
[-68.8 -41.9 53699]
[17.6 18.2 34023]
[-44.1 -2.7 223604]
[102.4 50.5 50888]
[-121.8 37.6 113270]
[121.8 40.2 991032]
[24.7 62.6 89358]
[31.8 46.4 453082]
[42.4 13 206823]
[-74.1 3 42455]
[-97.1 35.8 760170]
[47.6 -21.8 209760]
[-102.4 40.2 17158]
[-10.6 47.8 102782]
[107.6 27.4 2684928]
[81.2 37.1 14348]
[148.2 -33.4 14348]
[-98.8 25.4 213242]
[37.1 27.4 20137]
[15.9 -2.7 96280]
[3.5 35.8 45266]
[74.1 41.2 194783]
[72.4 66.8 53699]
[-70.6 -37.8 53699]
[95.3 34.3 50888]
[31.8 -13.4 653612]
[141.2 40.2 643963]
[-95.3 43.6 39099]
[68.8 60 53699]
[10.6 50.5 602557]
[-70.6 43.6 41365]
[-1.8 46.4 2286384]
[121.8 39.2 1510817]
[88.2 46.4 53699]
[42.4 25.4 234931]
[67.1 39.7 748843]
[-90 39.2 282756]
[52.9 65.1 53699]
[81.2 66 53699]
[-91.8 42.3 38722]
[40.6 39.2 316738]
[-100.6 20 331840]
[24.7 71.1 16697]
[-70.6 -33.4 1238843]
[142.9 45 30205]
[88.2 32.7 79247]
[74.1 60.9 223604]
[95.3 38.1 14348]
[74.1 72 24584]
[7.1 63.4 36834]
[95.3 23.5 1459091]
[-74.1 -2.7 46986]
[-67.1 -20.1 53699]
[79.4 67.7 53699]
[-88.2 42.3 10068]
[38.8 60 742550]
[-93.5 38.1 182911]
[40.6 67.7 13970]
[-5.3 60 1241360]
[141.2 -13.4 13802]
[-120 42.3 84869]
[49.4 32.7 29366]
[98.8 13 392251]
[17.6 47.8 1803936]
[-112.9 45 48077]
[61.8 38.6 53699]
[56.5 25.4 53699]
[-75.9 -15 14683]
[70.6 71.1 53699]
[-60 9.1 11537]
[172.9 -37.8 42791]
[-98.8 40.7 50972]
[35.3 25.4 22318]
[24.7 60.9 813869]
[-72.4 1 22780]
[-54.7 -20.1 120738]
[54.7 45 53699]
[26.5 21.7 19969]
[112.9 7.1 182491]
[88.2 47.8 144315]
[-58.2 -6.3 45266]
[-74.1 13 289469]
[93.5 45 19969]
[-51.2 -4.5 53699]
[42.4 61.7 189623]
[-98.8 23.5 1065581]
[-51.2 -20.1 2684928]
[15.9 46.4 2055648]
[77.6 42.3 44175]
[84.7 40.2 39645]
[104.1 37.1 1749398]
[8.8 5 229897]
[95.3 50.5 39645]
[-56.5 -23.4 221507]
[47.6 16.5 10068]
[12.4 -15 50972]
[22.9 -6.3 289469]
[63.5 43.6 50888]
[150 -25.1 50888]
[-42.4 -4.5 99007]
[-70.6 66 11537]
[-60 -37.8 377568]
[97.1 38.1 31212]
[67.1 70.2 46986]
[77.6 62.6 50342]
[86.5 27.4 3251280]
[-58.2 -23.4 234805]
[37.1 1 1251428]
[67.1 45 121661]
[22.9 39.7 1151582]
[84.7 40.7 165039]
[54.7 21.7 53699]
[-79.4 42.3 28402]
[-10.6 7.1 10068]
[15.9 1 33478]
[65.3 46.4 53699]
[44.1 42.3 65110]
[114.7 46.4 53699]
[-81.2 1 197174]
[-61.8 -2.7 10446]
[-102.4 31.2 67459]
[-77.6 -4.5 53699]
[21.2 40.2 2433216]
[28.2 50.5 262200]
[-65.3 -39.2 46986]
[33.5 69.4 53699]
[-54.7 -15 99007]
[-84.7 40.2 1296317]
[98.8 25.4 899283]
[82.9 50.5 234931]
[79.4 50.5 234931]
[24.7 65.1 61669]
[109.4 1 248062]
[60 43.6 53699]
[-112.9 40.7 28485]
[47.6 45 263459]
[17.6 43.6 2055648]
[0 42.3 1021531]
[120 18.2 1713739]
[-79.4 40.2 759331]
[10.6 66 60117]
[114.7 -2.7 31003]
[0 13 1151582]
[0 40.2 578938]
[24.7 70.2 10991]
[51.2 64.3 53699]
[-72.4 68.5 11537]
[12.4 66 25591]
[49.4 35.8 643963]
[-49.4 -13.4 220248]
[95.3 29.4 129170]
[68.8 69.4 50888]
[125.3 50.5 50888]
[-60 -11.7 11537]
[150 -28.5 42455]
[-100.6 37.6 65110]
[67.1 37.6 316738]
[60 69.4 43630]
[-51.2 -18.4 484797]
[146.5 -6.3 26849]
[114.7 7.1 453082]
[-10.6 11.2 847430]
[-114.7 34.3 10068]
[-17.6 23.5 20137]
[-118.2 42.3 142301]
[-82.9 34.3 333225]
[70.6 41.2 42455]
[-84.7 39.7 595718]
[-51.2 -13.4 161347]
[81.2 68.5 53699]
[61.8 47.8 76353]
[-104.1 42.3 14348]
[-67.1 9.1 46986]
[24.7 14.8 223604]
[176.5 -36.5 13425]
[-65.3 -8.1 39645]
[51.2 67.7 53699]
[60 37.6 223604]
[116.5 39.7 895675]
[100.6 1 421198]
[-105.9 47.8 87680]
[49.4 37.1 497131]
[72.4 35.8 2999568]
[72.4 38.6 31296]
[70.6 72 39099]
[-79.4 -4.5 643544]
[45.9 62.6 121661]
[68.8 64.3 53699]
[128.8 43.6 302054]
[125.3 40.2 2181504]
[-51.2 -15 234931]
[121.8 1 44050]
[114.7 37.1 4363008]
[-109.4 39.7 17158]
[47.6 -16.7 294084]
[-3.5 49.1 1450700]
[-58.2 -36.5 629280]
[-72.4 -44.6 11537]
[-52.9 -31.8 59278]
[-56.5 -20.1 56593]
[70.6 43.6 14348]
[-90 38.6 545921]
[38.8 9.1 632217]
[31.8 43.6 671232]
[31.8 23.5 42455]
[35.3 63.4 122080]
[70.6 31.2 658227]
[30 68.5 53699]
[-15.9 18.2 388056]
[1.8 32.7 25591]
[148.2 -31.8 70731]
[52.9 41.2 53699]
[75.9 20 2684928]
[100.6 35.8 87680]
[130.6 35.8 1342464]
[-68.8 3 14348]
[51.2 42.3 36918]
[21.2 39.2 450984]
[65.3 39.2 316738]
[82.9 41.2 90574]
[118.2 29.4 2035217]
[102.4 31.2 2265408]
[-19.4 66.8 10991]
[-109.4 45 11537]
[10.6 35.8 271052]
[-84.7 67.7 14348]
[-72.4 7.1 59404]
[86.5 23.5 440496]
[54.7 20 10068]
[7.1 61.7 36372]
[-86.5 16.5 651515]
[100.6 20 966994]
[107.6 34.3 2726880]
[86.5 61.7 53699]
[82.9 29.4 4258128]
[81.2 21.7 1048800]
[63.5 35.8 155642]
[42.4 14.8 188490]
[45.9 13 92294]
[-93.5 20 551669]
[14.1 -6.3 186812]
[98.8 11.2 880992]
[141.2 61.7 20137]
[109.4 45 53699]
[17.6 -20.1 17158]
[33.5 65.1 47532]
[135.9 61.7 53699]
[-7.1 20 45266]
[79.4 72 30667]
[33.5 39.7 316738]
[12.4 -6.3 27940]
[82.9 23.5 2307360]
[12.4 38.1 335616]
[-98.8 35.8 107523]
[-60 7.1 45434]
[38.8 11.2 1023629]
[-12.4 14.8 1019014]
[-8.8 16.5 216892]
[51.2 46.4 248775]
[151.8 -31.8 29366]
[21.2 62.6 74675]
[-75.9 39.2 2244432]
[-10.6 39.2 14683]
[-12.4 13 220248]
[35.3 3 290727]
[-148.2 66 14348]
[-77.6 40.7 146832]
[-1.8 50.5 224443]
[58.2 25.4 40274]
[47.6 38.6 1132704]
[102.4 20 2684928]
[107.6 39.7 427910]
[38.8 43.6 2181504]
[-51.2 -0.9 46986]
[74.1 37.6 205565]
[-81.2 35.8 104041]
[47.6 -13.4 171584]
[19.4 9.1 31212]
[86.5 40.2 90574]
[49.4 34.3 478253]
[109.4 62.6 22780]
[111.2 47.8 53699]
[-58.2 1 53699]
[67.1 71.1 53699]
[44.1 16.5 1778765]
[61.8 34.3 50888]
[56.5 40.7 53699]
[5.3 37.1 152831]
[116.5 41.2 11537]
[21.2 -28.5 17158]
[52.9 47.8 234931]
[-56.5 -2.7 53699]
[68.8 40.7 53699]
[120 43.6 303145]
[-54.7 43.6 43630]
[95.3 21.7 1333235]
[72.4 25.4 2873712]
[98.8 9.1 755136]
[70.6 38.1 129716]
[19.4 11.2 28485]
[61.8 40.7 53699]
[116.5 29.4 2307360]
[35.3 37.6 1219964]
[56.5 66.8 53699]
[38.8 13 1443149]
[22.9 67.7 36834]
[72.4 72 14515]
[77.6 29.4 2433216]
[-8.8 38.6 220500]
[31.8 47.8 1245974]
[-91.8 16.5 755136]
[28.2 14.8 144315]
[82.9 60.9 53699]
[84.7 62.6 42455]
[79.4 34.3 497467]
[88.2 29.4 3544944]
[74.1 32.7 2181504]
[135.9 37.6 2238685]
[-63.5 3 11537]
[127.1 3 211396]
[-54.7 -16.7 42455]
[112.9 39.7 1023629]
[33.5 37.6 41952]
[33.5 38.1 757234]
[54.7 68.5 53699]
[-104.1 37.6 28485]
[148.2 -4.5 13425]
[109.4 38.1 1803936]
[37.1 11.2 2013696]
[60 45 53699]
[21.2 50.5 1147387]
[40.6 38.1 1300512]
[-79.4 -2.7 214794]
[-104.1 35.8 42455]
[84.7 21.7 167808]
[72.4 39.2 531112]
[128.8 49.1 53699]
[116.5 37.1 2873712]
[72.4 31.2 1623542]
[49.4 49.1 532790]
[65.3 34.3 874699]
[35.3 37.1 1875800]
[-8.8 18.2 65026]
[26.5 41.2 1929792]
[24.7 -11.7 48077]
[93.5 27.4 382602]
[26.5 65.1 110334]
[77.6 37.6 200950]
[-65.3 -25.1 242063]
[144.7 -33.4 17158]
[-63.5 -15 53699]
[22.9 -20.1 22780]
[33.5 -4.5 234931]
[-72.4 -36.5 481609]
[-68.8 -20.1 53699]
[56.5 43.6 53699]
[107.6 62.6 53699]
[-91.8 20 112683]
[17.6 -2.7 298698]
[37.1 64.3 53699]
[-105.9 45 53866]
[17.6 -16.7 61753]
[-77.6 38.1 302054]
[82.9 21.7 1929792]
[0 35.8 53699]
[-104.1 39.7 65110]
[74.1 39.2 73542]
[-67.1 -30.1 65026]
[37.1 45 2307360]
[-74.1 -6.3 31212]
[30 46.4 1415880]
[-114.7 37.6 232456]
[-67.1 77.3 10446]
[-109.4 46.4 14348]
[54.7 38.6 169486]
[114.7 40.7 34023]
[104.1 62.6 48077]
[125.3 45 150020]
[-72.4 -6.3 11537]
[-44.1 -21.8 889382]
[107.6 14.8 670812]
[74.1 50.5 234931]
[14.1 16.5 96280]
[112.9 60 53699]
[63.5 37.6 197594]
[44.1 25.4 234931]
[105.9 20 1245974]
[37.1 67.7 53699]
[104.1 18.2 2531803]
[38.8 3 36834]
[144.7 -4.5 40274]
[104.1 65.1 11537]
[-75.9 42.3 39645]
[-109.4 31.2 100349]
[97.1 47.8 53699]
[114.7 47.8 53699]
[44.1 69.4 13425]
[-67.1 -31.8 53699]
[58.2 63.4 212277]
[107.6 18.2 497551]
[68.8 67.7 40274]
[15.9 63.4 130890]
[-38.8 -11.7 436301]
[37.1 -13.4 314640]
[-52.9 -6.3 53699]
[-88.2 38.6 515171]
[84.7 66 48077]
[-67.1 -23.4 53699]
[42.4 63.4 53699]
[-8.8 40.2 1470418]
[-95.3 39.7 99007]
[28.2 7.1 80967]
[52.9 45 53699]
[105.9 43.6 53699]
[130.6 42.3 760590]
[5.3 62.6 113396]
[77.6 61.7 53699]
[77.6 47.8 53699]
[-90 35.8 216892]
[116.5 62.6 27856]
[40.6 -0.9 28108]
[-67.1 43.6 46986]
[68.8 37.1 1487198]
[-79.4 38.6 100811]
[-1.8 38.6 1218706]
[-84.7 42.3 32387]
[15.9 -13.4 124555]
[51.2 60 660744]
[-40.6 -20.1 167808]
[98.8 14.8 223185]
[47.6 13 53699]
[17.6 61.7 455179]
[28.2 21.7 45266]
[-54.7 -18.4 19969]
[-112.9 31.2 11075]
[75.9 70.2 53699]
[38.8 37.6 220248]
[95.3 45 31212]
[135.9 -0.9 33562]
[-63.5 -37.8 492936]
[-90 42.3 20137]
[128.8 47.8 53699]
[15.9 -16.7 189623]
[-116.5 40.7 84030]
[82.9 63.4 53699]
[-61.8 -35.1 671232]
[112.9 31.2 2720587]
[-61.8 -15 53699]
[120 39.2 168353]
[-121.8 49.1 42455]
[14.1 39.2 182491]
[37.1 18.2 390573]
[49.4 -13.4 117466]
[-98.8 31.2 181904]
[105.9 60.9 53699]
[49.4 60 425813]
[14.1 9.1 99007]
[17.6 65.1 44175]
[134.1 45 53699]
[-72.4 -46 11537]
[40.6 37.6 468856]
[40.6 13 112222]
[15.9 68.5 31212]
[24.7 -20.1 53699]
[-5.3 40.2 635573]
[100.6 3 138861]
[-86.5 34.3 320513]
[24.7 32.7 19969]
[-148.2 70.2 10991]
[-100.6 29.4 170577]
[37.1 43.6 2684928]
[-79.4 11.2 34820]
[38.8 -15 364982]
[38.8 7.1 65026]
[28.2 -8.1 146119]
[37.1 7.1 239252]
[-109.4 32.7 28402]
[-118.2 41.2 47616]
[132.4 -0.9 40819]
[44.1 34.3 70270]
[14.1 18.2 39645]
[3.5 37.1 189623]
[35.3 43.6 2559072]
[22.9 47.8 1300512]
[28.2 -31.8 377568]
[70.6 37.1 2873712]
[-88.2 41.2 122919]
[-77.6 -9.9 1778765]
[22.9 -16.7 48077]
[47.6 20 53699]
[167.6 -44.6 25759]
[-72.4 -28.5 39435]
[146.5 -36.5 21689]
[8.8 38.1 895675]
[12.4 61.7 125353]
[33.5 -0.9 826454]
[37.1 40.7 167808]
[33.5 47.8 868406]
[109.4 27.4 1959158]
[104.1 23.5 1778765]
[104.1 20 742131]
[88.2 41.2 34023]
[-97.1 46.4 13257]
[-35.3 -8.1 209760]
[22.9 -30.1 19969]
[15.9 47.8 1552224]
[-63.5 -6.3 11537]
[45.9 43.6 163613]
[21.2 64.3 141504]
[-42.4 -20.1 381763]
[51.2 45 53699]
[-7.1 50.5 1048800]
[63.5 66 53699]
[-118.2 76.4 15606]
[-52.9 -30.1 195329]
[21.2 13 28402]
[-3.5 37.1 369178]
[44.1 39.7 1803936]
[22.9 32.7 42455]
[45.9 11.2 140959]
[47.6 31.2 22235]
[35.3 38.6 797088]
[51.2 65.1 53699]
[45.9 -21.8 164871]
[111.2 40.2 62215]
[21.2 60 1021531]
[91.8 23.5 482868]
[31.8 -2.7 803381]
[5.3 49.1 335616]
[-63.5 -18.4 53699]
[-22.9 76.4 10446]
[44.1 32.7 39099]
[95.3 32.7 22780]
[116.5 7.1 220248]
[65.3 47.8 53699]
[-104.1 37.1 50888]
[35.3 31.2 37463]
[88.2 43.6 65026]
[-98.8 43.6 56593]
[37.1 -4.5 370268]
[-70.6 3 16613]
[19.4 -16.7 28402]
[-58.2 -16.7 45266]
[-10.6 13 220248]
[68.8 61.7 53699]
[127.1 42.3 1048800]
[105.9 38.1 677525]
[-15.9 21.7 42455]
[3.5 32.7 11537]
[31.8 70.2 23493]
[-107.6 49.1 42455]
[118.2 35.8 2789808]
[61.8 60 234931]
[-111.2 49.1 45266]
[-118.2 72 12711]
[37.1 62.6 50342]
[-7.1 32.7 11537]
[81.2 43.6 53699]
[38.8 -9.9 788698]
[114.7 -31.8 81932]
[31.8 65.1 53699]
[-77.6 11.2 346230]
[74.1 60 205565]
[17.6 -13.4 17158]
[139.4 49.1 23493]
[45.9 67.7 27395]
[49.4 69.4 10614]
[-107.6 61.7 11537]
[54.7 60 234931]
[45.9 46.4 234931]
[120 50.5 53699]
[40.6 27.4 121661]
[7.1 7.1 1929792]
[100.6 14.8 41952]
[120 32.7 2496144]
[-67.1 -13.4 11537]
[88.2 62.6 11537]
[-116.5 50.5 11537]
[-49.4 -16.7 186267]
[-121.8 76.4 11621]
[-72.4 -43.3 28402]
[-82.9 32.7 649417]
[102.4 16.5 1330424]
[-58.2 -30.1 99007]
[-116.5 37.6 233924]
[121.8 14.8 503424]
[-52.9 3 53866]
[116.5 49.1 53699]
[22.9 50.5 671232]
[114.7 60 53699]
[109.4 -6.3 2894688]
[30 -23.4 319884]
[26.5 60.9 581581]
[123.5 9.1 1720032]
[67.1 60.9 53699]
[112.9 62.6 19969]
[60 66 53699]
[-121.8 43.6 590265]
[-70.6 11.2 248775]
[30 60 234931]
[97.1 7.1 293664]
[111.2 37.1 2789808]
[-74.1 -35.1 41952]
[-72.4 14.8 73416]
[38.8 46.4 1300512]
[-104.1 21.7 156607]
[-8.8 7.1 67543]
[35.3 13 490964]
[35.3 18.2 305411]
[112.9 32.7 2433216]
[10.6 64.3 45266]
[44.1 20 471289]
[30 25.4 11537]
[141.2 42.3 30205]
[24.7 61.7 234931]
[67.1 63.4 50342]
[-107.6 40.7 28402]
[75.9 43.6 101901]
[-54.7 3 34023]
[128.8 35.8 16319]
[-116.5 43.6 56593]
[171.2 -40.5 35743]
[102.4 -2.7 591523]
[81.2 50.5 234931]
[-70.6 1 11537]
[82.9 64.3 53699]
[97.1 32.7 24500]
]
 set the-army-camps [["USA" [["Camp Grant" 42.30 -89.09 50000 500]
         ["Camp Pike" 34.75 -92.29 53000 500]
         ["Camp Lee" 37.25 -77.33 19000 200]
         ["Camp Devens" 42.50 -71.66 40000 400]
         ["Camp Upton" 40.84 -72.92 40000 400]
         ["Camp Dix" 40.03 -74.62 40000 400]
         ["Camp Meade" 39.20 -76.65 40000 400]
         ["Camp Jackson" 33.31 -81.81 40000 400]
         ["Camp Gordon" 33.88 -84.31 40000 400]
         ["Camp Sherman" 39.34 -83.031 40000 400]
         ["Camp Taylor" 38.2 -85.72 40000 400]
         ["Camp Custer" 42.31 -85.34 40000 400]
         ["Camp Dodge" 41.7 -93.71 40000 400]
         ["Camp Funston" 39.22 -96.93 40000 400]
         ["Camp Travis" 29.46 -98.44 40000 400]
         ["Camp Lewis" 45.17 -122.56 40000 400]]]
 ["Britain and Northern France"
        [["Etaples" 47.4 1.63 2000000 100000]]]
]
 set the-population-movements [
[2 [["New York" 7 4 3000 3000]
    ["Liverpool" 7 4 3000 3000]]]
[3 [["San Francisco" 7 3 3000 3000]
    ["Honolulu" 7 3 1000 1000]
    ["Tokyo" 4 3 1000 1000]
    ["Shanghai" 14 3 3000 3000]]]
[3 [["Shanghai" 4 3 3000 3000]
    ["Tokyo" 7 3 1000 1000]
    ["Honolulu" 7 3 1000 1000]
    ["Seattle" 14 3 3000 3000]]]
[4 [["Bristol" 10 3 3000 3000]
    ["Panama Canal" 14 3 100 100]
    ["Auckland" 2 3 1000 1000]
    ["Sydney" 2 3 3000 3000]]]
[5 [["Liverpool" 3 8 3000 3000]
    ["Lisbon" 2 2 100 100]
    [[25 -22] 2 0 0 0]
    ["Dakar" 4 2 100 100]
    ["Cape Town" 4 2 500 500]
    ["Bombay" 8 3 3000 3000]]]
[6 [["Liverpool" 3 8 1000 1000]
    ["Lisbon" 2 2 100 100]
    [[25 -22] 2 0 0 0]
    ["Dakar" 4 2 100 100]
    ["Recife" 5 8 100 100]]]
[[239 1918]
   [["Liverpool" 4 2 4000 4000]
    [[71 -1] 4 1 0 0]
    [[75 26] 3 1 0 0]
    ["Archangel" 2 0 4000 0]]
 2]
]
;[1 [["San Francisco" 1 1 500 500 "train"]
;    ["Salt Lake City" 1 1 100 100 "train"]
;    ["Denver" 1 1 100 100 "train"]
;    ["Kansas City" 1 1 100 100 "train"]
;    ["Chicago" 1 1 100 100 "train"]
;    ["New York" 5 1 500 500 "train"]]]
 set the-places [
["Quebec City" 46.81 -71.21]
["Montreal" 45.52 -73.55]
["St. John's" 47.57 -52.71]
["Halifax" 44.65 -63.58]
["Portland" 43.67 -70.26]
["Boston" 42.36 -71.06]
["New York" 40.73 -74.00]
["Philadelphia" 39.96 -75.16]
["Baltimore" 39.30 -76.61]
["Newport News" 37.10 -78]
["Glasgow" 55.87 -4.25]
["Manchester" 53.48 -2.25]
["Liverpool" 53.42 -2.99]
["Bristol" 51.46 -2.59]
["Falmouth" 50.15 -5.07]
["Plymouth" 50.38 -4.14]
["Southampton" 50.90 -1.40]
["London" 51.52 -2]
["Le Havre" 49.50 0.11]
["Brest" 48.39 -4.49]
["Saint-Nazaire" 47.28 -2.21]
["Bordeaux" 44.84 -0.58]
["Marseilles" 43.31 5.38]
["Dakar" 14.76 -17.33]
["Freetown" 8.49 -13.23]
["Cape Town" -33.90 18.42]
["Bombay" 19.10 72.87]
["Calcutta" 22.71 90.9]
["Auckland" -36.82 174.76]
["Sydney" -33.87 150.8]
["Melbourne" -37.81 144.96]
["San Francisco" 37.78 -122.42]
["Seattle" 46.6 -122.34]
["Panama Canal" 11 -79.60]
["Archangel" 64.47 40.50]
["Lisbon" 38.71 -9.13]
["Cairo" 30.05 31.24]
["Shanghai" 31.26 120.8]
["Tokyo" 37.5 139.77]
["Recife" -8.05 -34.88]
["Salt Lake City" 40.77 -111.89]
["Denver" 39.77 -104.98]
["Kansas City" 39.13 -94.57]
["Chicago" 41.89 -87.63]
["Honolulu" 21.3 -156.86]
]
 set the-index-cases-camp-funston [[62 1918 -97 39 1]]
 ; start on 4 March 1918
 ; first reported case in Camp Funston
 set the-index-cases-etaples [[334 1916 1.63 48.4 10]]
 ; start December 1916
 set the-odds-history [
[334 1916 .009  .001]
[ 30 1918 .10   .005]
[150 1918 .02   .001]
[230 1918 .25   .030]
[290 1918 .02   .015]
[  5 1919 .10   .005]
]
 set the-encounter-rate-changes [
[357 1917 2   -166 46 27 76]
[358 1917 2   -166 46 27 76]
[359 1917 2   -166 46 27 76]
[357 1918 2   -166 46 27 76]
[358 1918 2   -166 46 27 76]
[359 1918 2   -166 46 27 76]
]
; Christmas in
; US, Canada, and Europe
 set the-global-dead 0
 set the-global-dead-previous-day 0
 set the-global-susceptibles 0
 set the-global-infected 0
 set the-global-recovered 0
 set the-fraction-not-susceptible 0
 set the-pixel-latitude-map [
[0 -55.5]
[6.3 -47]
[15 -35.1]
[20.7 -25.6]
[28.8 -12]
[35.5 0]
[41.4 12]
[47.8 23.1]
[51.6 30.5]
[55.8 37]
[64.4 41.4]
[71.6 51.3]
[70.1 58.4]
[85 71.1]
[93.8 78.9]
]
 set the-average-duration 4.68
 set the-average-infection-odds .1
 set the-average-mortality-odds .025
 set the-ship-encounter-rate 30
 set the-encounter-rate 10
 set the-medium-distance-travel-destinations-count 4
 set the-maximum-medium-distance-travel 5
 set the-medium-distance-travel-fraction .1
 set the-default-buttons-should-not-be-added true
 set update-patch-attributes-needed false
end

to update-patch-attributes
end

to-report update-turtle-state
 report false
end

to initialise-previous-state
end

to update-all-turtle-states
end

to initialise-attributes
 set my-next-infected-set false
 set my-next-susceptibles-set false
 set my-next-recovered-set false
 set my-next-dead-set false
 set my-next-others-set false
end

to start
 file-close
 initialise
 the-model
 finish-setup
 create-pens 1 ; for drawing lines
 ask pens [hide-turtle]
end

to setup
 nested-no-display
 start
 set total-time 0
 if go-until (delta-t - .000001) []  ; ignore result
 ask objects [initialise-previous-state]
 nested-display
end

; allow regions of code to temporarily turn off the display process even if their execution is nested

to nested-no-display
  no-display
  set no-display-count no-display-count + 1
end

to nested-display
  set no-display-count no-display-count - 1
  if no-display-count < 0 [set no-display-count 0]
  if no-display-count = 0 [display]
end

to initialise
 if-else maximum-plot-generations > 0 and any? objects
    [if-else plot-generation <= maximum-plot-generations
        [set plot-generation plot-generation + 1
          ; clear all but plots and output
         clear-patches
         clear-drawing
         clear-turtles]
        [clear-all
         set plot-generation 0]]
    [clear-all]
 reset-ticks
 reset-timer
 set time -1
 set times-scheduled []
 set behind-schedule 0
 set plotting-commands []
 set histogram-plotting-commands []
 set button-command ""
 set radian 57.29577951308232
 set need-to-clear-drawing false
 set observer-commands []
 set stop-running false
 if delta-t = 0 [set delta-t 1] ; give default value if none given
 if frame-duration = 0 [set frame-duration delta-t]
 if world-geometry = 0 [set world-geometry 1]
 set half-world-width world-width / 2
 set half-world-height world-height / 2
 set negative-half-world-width (- half-world-width)
 set negative-half-world-height (- half-world-height)
 ask-every-patch [ [] -> initialise-patch-attributes ]
end

to initialise-object
 set scheduled-behaviours []
 set current-behaviours []
 set behaviour-removals []
 set rules []
 set dead false
 initialise-attributes
end

to finish-setup
 ; faster than ask objects since doesn't shuffle
 set objects-with-something-to-do objects
 let ignore1 objects with [update-attributes]
 ask objects with [rules != []] [run-rules]
 update-all-turtle-states
 set time 0
end

to go
 reset-timer ; reset timer so pause and resume don't have leftover time
 if go-until -1
    [set stop-running false ; so it can be started up again
     stop]
    set total-time total-time + timer
end

to setup-only-if-needed
  if times-scheduled = 0 [setup]
end

to-report go-until [stop-time]
 ; this is run by the 'go' button and runs the scheduled events and updates the turtle states and plots
 setup-only-if-needed
 nested-no-display
 if-else times-scheduled = []
   ; following uses a hack to avoid the overhead of ask shuffling the agent set
   [set objects-with-something-to-do objects with [rules != []]
    ask objects-with-something-to-do [run-rules] ; nothing scheduled but rules may be triggered by time
    ; rules may have added behaviours or set 'dead' so can't re-use objects-with-something-to-do
    ask objects [finish-tick]
    set time time + frame-duration]
   [if-else time <= 0
      [set cycle-finish-time first times-scheduled]
      [set cycle-finish-time cycle-finish-time + frame-duration]
     if stop-time > 0 [set cycle-finish-time stop-time]
     while [times-scheduled != [] and first times-scheduled <= cycle-finish-time]
       [; nothing happening so skip ahead to next event
        set time first times-scheduled
        set times-scheduled but-first times-scheduled
        set objects-with-something-to-do objects with [scheduled-behaviours != [] or rules != []]
        ask objects-with-something-to-do [start-tick]
        ; above may have added behaviours or set 'dead' so can't re-use objects-with-something-to-do
        ask objects [finish-tick]
        if need-to-clear-drawing
           [clear-drawing
            set need-to-clear-drawing false]]]
 update-all-turtle-states
 if update-patch-attributes-needed [ask-every-patch [ [] -> update-patch-attributes ]]
 tick-advance time - ticks
 run-plotting-commands
 if observer-commands != []
    [let commands observer-commands
     set observer-commands []
     ; run each command without any commands pending
     forEach commands [ ?1 -> run ?1 ]]
 nested-display
 if count objects = 0 or stop-running or (stop-time > 0 and time >= stop-time)
   [file-close-all ; in case any files are open
    report true]
 report false
end

to run-plotting-commands
 forEach plotting-commands [ ?1 -> if is-agent? first ?1 [ask first ?1 [update-plot second ?1 runresult third ?1 runresult fourth ?1]] ]
 forEach histogram-plotting-commands [ ?1 -> if is-agent? first ?1 [ask first ?1 [update-histogram second ?1 third ?1 fourth ?1]] ]
end

to add-to-plot [x y]
  ; if using multiple plot generations need to get the pen back to the beginning without drawing a line
  ; assumes the plot starts at zero (or very close to it -- after setup)
  if-else x <= .000001
     [plot-pen-up plotXY x y plot-pen-down]
     [plotXY x y]
end

to create-plot [name-of-plot x-label y-label x-code y-code]
 ; working around a limitation of NetLogo that only via the Controller can new plots be created
 ; some of the arguments are only of use to the BehaviourComposer
  set plotting-commands fput (list self name-of-plot x-code y-code) plotting-commands
end

to create-histogram [name-of-plot x-label y-label x-code y-code]
  set histogram-plotting-commands fput (list self name-of-plot x-code y-code) histogram-plotting-commands
  set-current-plot name-of-plot
  set-plot-pen-mode 1 ; bars
end

to update-plot [name-of-plot x y]
 if time >= 0
  [set-current-plot name-of-plot
   plotxy x y]
end

to update-histogram [name-of-plot population-reporter value-reporter]
 if time >= 0
  [set-current-plot name-of-plot
   histogram [runresult value-reporter] of runresult population-reporter]
end

;; behaviours are represented by a list:
;; scheduled-time behaviour-name
;; behaviours are kept in ascending order of the scheduled-time

to add-link-behaviours-after [delay behaviours]
 add-link-behaviours behaviours time + delay
end

to add-link-behaviour-after [delay name]
 add-link-behaviour name time + delay
end

to add-link-behaviours [behaviours when-to-add]
 foreach behaviours [ ?1 -> add-link-behaviour ?1 when-to-add ]
end

to add-link-behaviour [name when-to-add]
 ; links don't have their own schedule
 ; instead they use the agent at the "other end"
 let this-link self
 ask other-end [add-behaviour-to-link this-link name when-to-add]
end

to add-behaviour-to-link [this-link name when-to-add]
 ; save current-behaviour in case this was called by a behaviour that isn't finished
 let saved-current-behaviour current-behaviour
 let full-name (list name this-link)
 if-else when-to-add <= time
    [set current-behaviour (list maximum 0 when-to-add full-name)
     run-procedure full-name
     set current-behaviour saved-current-behaviour]
    [insert-behaviour when-to-add (list full-name)]
end

to remove-behaviour-now [name]
 set scheduled-behaviours remove-behaviour-from-list name scheduled-behaviours
end

to do-every [interval actions]
 ; does it now and schedules the next occurrence interval seconds in the future
 ; schedules first in case action updates the current-behaviour variable
 if-else not is-number? interval or interval <= 0
   [user-message (word "Can only repeat something a positive number of times. Not " interval " " actions)]
   [if-else time < 0
      [insert-behaviour 0 (list (list actions interval))]
      [do-every-internal interval actions]]
end

to do-every-internal [interval actions]
 insert-behaviour time + interval (list (list actions interval))
 run-procedure actions
end

to do-after-setup [actions]
 ; do actions 1/1000000 of a second after setup has completed
 do-at-time .000001 actions
end

to do-with-probability [odds actions]
 ; no longer generated
 ; remove from MB.5 and above
 if odds >= random-float 1
    [run actions]
end

to do-repeatedly [repeat-count actions]
 ; runs actions repeat-count times
 ; if a non-integer uses the remainder as the odds of doing the action one additional time
 repeat round repeat-count [run actions]
 let extra repeat-count - round repeat-count
 if extra > 0 and extra >= random-float 1
    [run actions]
end

to-report select-n [n agents]
 ; selects n from agents
 ; if n is a non-integer uses the remainder as the odds of selecting an additional agent
 ; if there are fewer than n agents then all agents run the actions just once
 let agent-count count agents
 if-else agent-count >= n
   [let n-floored floor n
    let extra n - n-floored
    if extra > 0 and agent-count > n
       [if-else extra >= random-float 1
          [set n n-floored + 1]
          [set n n-floored]]
        report n-of n agents]
   [report agents]
end

to do-for-n [n agents actions]
 ; set internal-the-other so each of the agents below can refer back to myself
 ; internal-the-other is global but set it for each one in case reset in the meanwhile
 ask select-n n agents [set internal-the-other myself run actions]
end

to do-at-time [scheduled-time actions]
 if-else scheduled-time <= time
   [run actions]
   [insert-behaviour scheduled-time (list actions)]
end

to do-after [duration actions]
 ; schedules this duration seconds in the future
 if-else is-list? current-behaviour
    ; from the time this event was scheduled to run; not necessarily the current time
    [do-at-time first current-behaviour + duration actions]
    [if-else time > 0
       [do-at-time time + duration actions]
       [do-at-time duration actions]]
end

to do-if [condition actions]
 ; uses = true in case condition is an unitialised variable that has the value of 0
 if runresult condition = true [run actions]
end

to add-copies [n behaviours]
 hatch n
       [set dead false
        let ignore update-attributes
        set scheduled-behaviours merge-behaviours scheduled-behaviours current-behaviours
        set scheduled-behaviours remove current-behaviour scheduled-behaviours
        forEach behaviours [ ?1 -> run ?1 ] ]
end

to-report add-copy [behaviours]
 report add-copy-of-another self behaviours
end

to-report add-copy-of-another [another behaviours]
 let copies add-copies-of-another 1 another behaviours
 if-else (copies = []) [report nobody] [report first copies]
end

to-report add-copies-of-another [n another behaviours]
 ; creates n copies of another (which can be another individual or the name of a kind of individual (if so a random one is chosen))
 if is-string? another [set another anyone-of-kind another]
 if not is-agent? another [report []]
 let copies []
 ask another [hatch n
               [set dead false
                let ignore update-attributes
                set scheduled-behaviours merge-behaviours scheduled-behaviours current-behaviours
                set scheduled-behaviours remove current-behaviour scheduled-behaviours
                forEach behaviours [ ?1 -> run ?1 ]
                set copies fput self copies]]
 report copies
end

to-report copy-agentset-to-list [agentset]
  let copies []
  ask agentset
      [hatch 1
        [set copies fput self copies]]
  report copies
end

to-report agentset-to-list [agentset]
  report [self] of agentset
end

to-report copy-agent [agent]
  let result nobody
  ask agent
      [hatch 1
        [set result self]]
  report result
end

to start-tick
  set current-behaviours scheduled-behaviours
  set scheduled-behaviours []
  while [current-behaviours != []]
        [let simulation-time first first current-behaviours
         if-else simulation-time > time
           [set scheduled-behaviours merge-behaviours scheduled-behaviours current-behaviours
            set current-behaviours []] ; stop this round
           [set current-behaviour first current-behaviours
            forEach but-first current-behaviour run-procedure
            set current-behaviour 0
            ; procedure may have reset current-behaviours to []
            if current-behaviours != []
               [set current-behaviours but-first current-behaviours]]]
  if rules != [] [run-rules]
  if behaviour-removals != []
     [forEach behaviour-removals
         [ ?1 -> ask first ?1 [remove-behaviour-now second ?1] ]
      set behaviour-removals []]
end

to finish-tick
 ; this should happen after all objects have run start-tick
 let ignore update-attributes
 if dead [die]
end

to-report not-me?
 ; used in a with statement to create an agentset that doesn't include self
 set internal-the-other myself
 report self != myself
end

to-report can-pick-one [agents]
 ; picks one and reports true unless there are no agents
 if-else any? agents
   [set internal-the-other one-of agents
    report true]
   [report false]
end

to-report any [kind-name]
 let agents objects with [kind = kind-name and self != myself and not hidden?]
 if-else any? agents
    [set internal-the-other one-of agents
     report true]
    [report false]
end

to-report anyone-of-kind [kind-name]
 ; finds any individual whose kind is equal to kind-name
 let agents objects with [kind = kind-name]
 if-else any? agents
    [report one-of agents]
    [report nobody]
end

to-report any-of-kind [kind-name]
 ; old name
 let agents objects with [kind = kind-name]
 if-else any? agents
    [report one-of agents]
    [report nobody]
end

to-report prototype-named [name]
  ; now is same as all-of-kind
  ; used to choose among the prototypes but that no longer makes sense
  report anyone-of-kind name
end

to-report all-of-kind [kind-name]
 report objects with [kind = kind-name]
end

to-report anyone
 report one-of objects with [self != myself and not hidden?] ; anyone who is visible and not me
end

to-report all-individuals
 report objects with [not hidden?]
end

to-report all-others
 report objects with [self != myself and not hidden?]
end

to all-who-are [predicate code]
 ; find other agents that match predicate and runs code on all of them
 let agents objects with [not-me? and not hidden? and runresult predicate]
 let me self
 ask agents [set internal-the-other self ask me [run code]]
end

to anyone-who-is [predicate code]
 ; find other agents that match predicate and runs code on one of them
 let agents objects with [not-me? and not hidden? and runresult predicate]
 if any? agents
   [let me self
    ask one-of agents [set internal-the-other self ask me [run code]]]
end

to-report distance-to-me
 report distance myself ; distance between myself and self
end

to-report distance-within [max-distance]
 report distance myself <= max-distance
end

to-report distance-between [min-distance max-distance]
 let d distance myself
 report d > min-distance and d <= max-distance
end

to when [condition action]
 set rules fput (list condition action false) rules
end

to whenever [condition action]
 set rules fput (list condition action true) rules
end

to run-rules
 let current-rules rules
 set rules []
 ; so can remove a rule below while still going down the list
 ;; could add error handling below
 forEach current-rules
    [ ?1 -> if-else runresult first ?1
       [run first but-first ?1
        if item 2 ?1
           ; is a whenever rule so put it back on the list of rules
           [set rules fput ?1 rules]]
       [set rules fput ?1 rules] ]
end

to insert-behaviour [scheduled-time rest-of-behaviour]
 ; inserts in schedule keeping it sorted by scheduled time
 set times-scheduled insert-ordered scheduled-time times-scheduled
 set scheduled-behaviours insert-behaviour-in-list scheduled-time rest-of-behaviour scheduled-behaviours
end

to-report insert-ordered [new-time times]
  if-else member? new-time times
    [report times]
    [report sort fput new-time times]
end

to-report insert-behaviour-in-list [scheduled-time rest-of-behaviour behaviours]
 ; recursive version took 10% longer
 let earlier-behaviours []
 while [behaviours != []]
    [let current-time first first behaviours
      if current-time = scheduled-time
        [let new-behaviour lput first rest-of-behaviour first behaviours
          report sentence earlier-behaviours fput new-behaviour but-first behaviours]
      if current-time > scheduled-time
        [report sentence earlier-behaviours fput fput scheduled-time rest-of-behaviour behaviours]
     set earlier-behaviours lput first behaviours earlier-behaviours
     set behaviours but-first behaviours]
 report sentence earlier-behaviours (list fput scheduled-time rest-of-behaviour)
end

to-report remove-behaviour-from-list [procedure-name behaviours]
 if behaviours = [] [report []]
 let first-behaviour-name behaviour-name first behaviours
 if equivalent-micro-behaviour? first-behaviour-name procedure-name
    [report but-first behaviours]
 report fput first behaviours remove-behaviour-from-list procedure-name but-first behaviours
end

to-report behaviour-name [scheduled-behaviour]
 if-else is-list? scheduled-behaviour
    [let behaviour second scheduled-behaviour
     if-else is-list? behaviour
        [report first behaviour]
        [report behaviour]]
    [report scheduled-behaviour]
end

to-report equivalent-micro-behaviour? [task-1 full-name-2]
 ; different copies of the same micro-behaviour are the same when it comes to removals
 let guid-and-hypen-length 6
 let task-description (word task-1)
 ; need to obtain the procedure name of the task by extracting it from print format
 ; ignore first 30 characters, guid, and final parenthesis
 if (length task-description - (guid-and-hypen-length + 1) <= 30) [report false]
 let name-1 substring task-description 30 (length task-description - (guid-and-hypen-length + 1))
 ; remove the unique guid from the end of the other procedure name
 let name-2 substring full-name-2 0 (length full-name-2 - guid-and-hypen-length)
 report name-1 = name-2
end

to remove-behaviours [behaviours]
 forEach behaviours [ ?1 -> remove-behaviour ?1 ]
end

to remove-behaviours-from [obj behaviours]
  if-else is-agent? obj or is-agentset? obj
    [ask obj [remove-behaviours behaviours]]
    [if obj != 0.0  ; no need to warn if uninitialised variable
       [user-message (word "Attempted to remove the behaviours " behaviours " from NOBODY.")]]
end

to remove-behaviour [name]
  set behaviour-removals fput (list self name) behaviour-removals
end


to remove-all-behaviours
  set scheduled-behaviours []
  set current-behaviours []
end

to remove-all-behaviours-from [obj]
  if-else is-agent? obj or is-agentset? obj
    [ask obj [remove-all-behaviours]]
    [if obj != 0.0  ; no need to warn if uninitialised variable
       [user-message (word "Attempted to remove all behaviours from NOBODY.")]]
end

to-report merge-behaviours [behaviours1 behaviours2]
 ; both lists are already sorted
 if behaviours1 = [] [report behaviours2]
 if behaviours2 = [] [report behaviours1]
 if-else first first behaviours1 < first first behaviours2
   [report fput first behaviours1 merge-behaviours but-first behaviours1 behaviours2]
   [report fput first behaviours2 merge-behaviours behaviours1 but-first behaviours2]
end

to-report random-integer-between [n1 n2]
 report n1 + random (1 + n2 - n1)
end

to-report random-number-between [n1 n2]
 report n1 + random-float (n2 - n1)
end

to-report random-item [items]
 report item random length items items
end

to-report maximum [n1 n2]
 if-else n1 > n2
   [report n1]
   [report n2]
end

to-report minimum [n1 n2]
 if-else n1 < n2
   [report n1]
   [report n2]
end

to-report second [l]
 report first but-first l
end

to-report third [l]
 report first but-first but-first l
end

to-report fourth [l]
 report first but-first but-first but-first l
end

to-report unit-vector [v]
 if (is-number? v) [report v]
; if wrapping [set v canonical-vector v]
 let distance-squared reduce [ [?1 ?2] -> ?1 + ?2 ] map [ ?1 -> ?1 * ?1 ] v
 if distance-squared = 0 [report 0] ; or an error?
 let dist sqrt distance-squared
 report map [ ?1 -> ?1 / dist ] v
end

to-report add [v1 v2]
 if is-number? v1 and is-number? v2 [report v1 + v2]
 if is-number? v1 [report map [ ?1 -> v1 + ?1 ] v2]
 if is-number? v2 [report map [ ?1 -> ?1 + v2 ] v1]
 report canonical-distance (map [ [?1 ?2] -> ?1 + ?2 ] v1 v2)
end

to-report subtract [v1 v2]
 if is-number? v1 and is-number? v2 [report v1 - v2]
 if is-number? v1 [report map [ ?1 -> v1 - ?1 ] v2]
 if is-number? v2 [report map [ ?1 -> ?1 - v2 ] v1]
 report canonical-distance (map [ [?1 ?2] -> ?1 - ?2 ] v1 v2)
end

to-report multiply [v1 v2]
 if is-number? v1 and is-number? v2 [report v1 * v2]
 if is-number? v1 [report map [ ?1 -> v1 * ?1 ] v2]
 if is-number? v2 [report map [ ?1 -> ?1 * v2 ] v1]
 report canonical-distance (map [ [?1 ?2] -> ?1 * ?2 ] v1 v2)
end

to-report divide [v1 v2]
 if is-number? v1 and is-number? v2 [report v1 / v2]
 if is-number? v1 [report map [ ?1 -> v1 / ?1 ] v2]
 if is-number? v2 [report map [ ?1 -> ?1 / v2 ] v1]
 report canonical-distance (map [ [?1 ?2] -> ?1 / ?2 ] v1 v2)
end

to-report is-zero? [v]
 if is-number? v [report v = 0]
 if v = [] [report true]
 if first v != 0 [report false]
 report is-zero? butFirst v
end

to-report reciprocal [n]
 ; avoids division by zero since often used in probability calculation
 if n = 0 [report 2147483647]
 report 1 / n
end

to-report direction-to-heading [direction]
 if direction = 0 [report heading]
 if direction = [0 0] [report heading]
 if direction = [0 0 0] [report heading]
 let x first direction
 let y second direction
 if horizontally-wrapping [set x remainder x world-width]
 if vertically-wrapping [set y remainder y world-height]
 report atan x y
end

to-report direction-vector [obj]
 report heading-to-direction [heading] of obj
end

to-report turn-by [direction angle]
 report heading-to-direction (direction-to-heading direction + angle)
end

to-report within-range [x minimum-value maximum-value]
 if x < minimum-value [report minimum-value]
 if x > maximum-value [report maximum-value]
 report x
end

to-report canonical-heading [h]
 if h > 180 [report h - 360]
 if h < -180 [report h + 360]
 report h
end

to-report all-values [variable]
 report [runresult variable] of all-individuals
end

to-report heading-towards [x y]
 ; should move this out of here and also make a 3D variant
 if xcor = x and ycor = y [report heading]
 report towardsxy x y
end

to-report heading-towards-another [another]
; should move this out of here and also make a 3D variant
 if is-patch? another
    [if xcor = [pxcor] of another and ycor = [pycor] of another [report heading]
     report towards another]
 if not is-agent? another [report heading]
 if xcor = [xcor] of another and ycor = [ycor] of another [report heading]
 report towards another
end


to ask-every-patch [procedure-name]
 ; a hack but faster since doesn't randomise the patches as ask does
 let ignore patches with [run-false procedure-name]
end

to-report run-false [procedure-name]
  run procedure-name
  report false
end

to-report coordinate-between [value min-value max-value modulo]
 ; reports true if value is between min-value and max-value using modulo
 ; assumes that negative values are shifted to between 0 and modulo
 set value value mod modulo
  if-else min-value >= 0
   [if-else max-value < modulo
      [report value >= min-value and value <= max-value]
      [report value >= min-value or value <= (max-value mod modulo)]]
   [if-else max-value < modulo
      [report value <= max-value or value >= (min-value mod modulo)]
      [report true]]
end

to-report canonical-coordinate [value min-value modulo]
 report ((value - min-value) mod modulo) + min-value
end

to set-world-geometry [code]
 set world-geometry code
end

to-report wrapping
 report world-geometry < 4
end

to-report horizontally-wrapping
 report world-geometry  < 3
end

to-report vertically-wrapping
 report world-geometry = 1 or world-geometry = 3
end

to-report camera-tracks-centroid
 report world-geometry = 5
end

to-report time-description
 if time < 0 [report " during setup."]
 if time <= .000001 [report " after setup."]
 report (word " after " time " seconds.")
end

to-report corresponding-agentset [agent-list]
  ; deprecated but kept for backwards compatibility
 report turtle-set agent-list
end

to-report list-to-agentset [agent-list]
  ; deprecated but kept for backwards compatibility
  report turtle-set agent-list
end

to-report my-location
 report make-location xcor ycor
end

to-report location [obj]
 report make-location [xcor] of obj [ycor] of obj
end

to-report heading-to-direction [h]
 report list sin h cos h
end

to draw-line [object1 object2 pen-color]
 ask pens [penup
           setxy [xcor] of object1 [ycor] of object1
           set color pen-color
           face object2
           pendown
           jump distance object2]
end

to-report random-unoccupied-location [min-xcor max-xcor min-ycor max-ycor]
 ; choose at random among the unoccupied locations
 let available-locations unoccupied-locations min-xcor max-xcor min-ycor max-ycor
 if-else any? available-locations
   [report [(list pxcor pycor)] of one-of available-locations]
   [report (list xcor ycor)]
end

to-report random-selection-of-unoccupied-locations [min-xcor max-xcor min-ycor max-ycor]
  ; old name --- maintained for backwards compatibility
  report random-unoccupied-location min-xcor max-xcor min-ycor max-ycor
end

to-report random-location-found-to-be-unoccupied [min-xcor max-xcor min-ycor max-ycor max-tries]
 ; this is obsolete but since existing models and micro-behaviours use this
 ; we implement it in terms of the new reporter
 report random-unoccupied-location min-xcor max-xcor min-ycor max-ycor
end

to-report unoccupied-locations [min-xcor max-xcor min-ycor max-ycor]
  report patches with [min-xcor <= pxcor and
                       max-xcor >= pxcor and
                       min-ycor <= pycor and
                       max-ycor >= pycor and
                       not any? objects-here with [not hidden?]]
end

; should replace the following with code that uses agentsets instead
to-report unoccupied-patches [list-of-patches]
 let result []
 foreach list-of-patches
         [ ?1 -> if not any? (objects-on ?1) with [not hidden?] [set result fput ?1 result] ]
 report result
end

; should replace the following with code that uses agentsets instead
to-report patches-between [min-x max-x min-y max-y]
 ; patches are ordered most distance first but ties are ordered randomly
 set min-x int min-x
 set min-y int min-y
 set max-x int max-x
 set max-y int max-y
 if min-x > max-x [report []]
 if min-y > max-y [report []]
 if min-x = max-x [if min-y = max-y [report (list patch-with-coordinates min-x min-y)]
                   report add-both-to-list patch-with-coordinates min-x min-y
                                           patch-with-coordinates min-x max-y
                                           patches-between min-x max-x (min-y + 1) (max-y - 1)]
 if min-y = max-y [report add-both-to-list patch-with-coordinates min-x min-y
                                           patch-with-coordinates max-x min-y
                                           patches-between (min-x + 1) (max-x - 1) min-y max-y]
 ; to do -- need to go around the outside so that the list is sorted by distance to the center
end

to-report add-both-to-list [a b l]
 if-else random 2 = 0
    [report fput a fput b l]
    [report fput b fput a l]
end

to-report patch-with-coordinates [x y]
 if horizontally-wrapping [set x canonical-coordinate x min-pxcor world-width]
 if vertically-wrapping [set y canonical-coordinate y min-pycor world-height]
 report patch x y
end

to-report canonical-vector [v]
 let x first v
 let y second v
 if horizontally-wrapping [set x remainder x world-width]
 if vertically-wrapping [set y remainder y world-height]
 report (list x y)
end

to-report canonical-distance [v]
 let x first v
 let y second v
 if horizontally-wrapping [if-else x > half-world-width [set x x - world-width] [if x < negative-half-world-width [set x x + world-width]]]
 if vertically-wrapping [if-else y > half-world-height [set y y - world-height] [if y < negative-half-world-height [set y y + world-height]]]
 report (list x y)
end

to-report make-location [x y]
 if horizontally-wrapping [set x canonical-coordinate x min-pxcor world-width]
 if vertically-wrapping [set y canonical-coordinate y min-pycor world-height]
 report (list x y)
end

to-report angle-from-me
 if distance myself = 0 [report 0]
 report canonical-heading (towards myself - heading)
end

to-report union [list1 list2]
 if empty? list1 [report list2]
 if empty? list2 [report list1]
 if-else random 2 = 0 [report union1 list1 list2]
                      [report union1 list2 list1]
end

to-report union1 [list1 list2]
 if member? first list1 list2 [report union but-first list1 list2]
 report fput first list1 union but-first list1 list2
end

to-report uninitialised? [x]
 report x = 0 ; uninitialised variables are zero
end

to run-procedure [name]
 if-else is-list? name
    [let target-or-frequency first but-first name
     if-else is-number? target-or-frequency
        [do-every-internal target-or-frequency first name]
        [ask target-or-frequency [run first name]]]
    [run name]
end

to-report transform-error-message [error-msg name]
  if-else (member? "WITH" error-msg) and (member? "agentset" error-msg) and (member? "0" error-msg)
         [report (word "A variable in the " name " micro-behaviour has not been initialised. At least one micro-behaviour is missing from the prototype " kind)]
         [report (word error-msg "\nNetLogo error in the micro-behaviour named " name)]
end

to-report transform-patch-error-message [error-msg name]
  report (word error-msg "\nNetLogo error in the micro-behaviour named " name)
end

to-report the-other
  if-else uninitialised? internal-the-other
    [user-message
      "A micro-behaviour uses 'the-other' and it hasn't been set. It can be set by micro-behaviours with calls to do-for-n, can-pick-one, any, all-who-are, or anyone-who-is."
     report nobody]
    [report internal-the-other]
end

to set-the-other [agent]
 set internal-the-other agent
end

to-report real-time
  ; for backwards compatibility
  report time
end

to-report add-to-list [x the-list]
 if-else is-list? the-list
    [report fput x the-list]
    [report (list x)]
end

to-report add-to-agentset [agent agentset]
  if-else is-agentset? agentset
          [report (turtle-set agent agentset)]
          [report (turtle-set agent)]
end

to layout-grid [agent-set-or-list lower-left-x lower-left-y width height]
  let agent-list []
  let agent-set nobody
  if-else is-agentset? agent-set-or-list
     [set agent-set agent-set-or-list
      set agent-list [self] of agent-set-or-list]
     [set agent-set list-to-agentset agent-set-or-list
      set agent-list agent-set-or-list]
  let x-min lower-left-x
  let x x-min
  let x-max x + width
  let y-min lower-left-y
  let y y-min
  let y-max y + height
  let maximum-agent-size max [size] of agent-set
  if maximum-agent-size <= 0 [set maximum-agent-size 1]
  while [y < y-max]
    [set x x-min
     while [x < x-max]
       [let agent first agent-list
        ask agent [setxy x y]
        set agent-list but-first agent-list
        if empty? agent-list [stop]
        set x x + maximum-agent-size]
    set y y + maximum-agent-size]
end

to-report other-objects-here
  report objects-here with [self != myself and not hidden?]
end

; following based on http://www.nr.com/forum/showthread.php?t=1396

to-report power-law-random [s maximum-value]
  let one-minus-s 1.0 - s
  let one-minus-s-inverse 1.0 / one-minus-s
  let hxm hfunction (maximum-value + 0.5) one-minus-s one-minus-s-inverse
  let hx0MinusHxm (hfunction 0.5 one-minus-s one-minus-s-inverse) - exp (ln 1.0 * (-1 * s)) - hxm;
  while [true]
    [let ur hxm + random-float 1.0 * hx0MinusHxm
     let x hinv ur one-minus-s one-minus-s-inverse
     let k floor (x + 0.5)
     if ((k - x) <= s) or ((ur >= ((hfunction k one-minus-s one-minus-s-inverse + 0.5) - exp(-1 * (ln (k + 1.0) * s)))))
        [report k]
    ]
end

to-report power-law-list [n power maximum-value]
  report n-values n [power-law-random power maximum-value]
end

to-report hfunction [x one-minus-s one-minus-s-inverse]
  report (exp (one-minus-s * ln (1.0 + x))) * one-minus-s-inverse
end

to-report hinv [x one-minus-s one-minus-s-inverse]
  report exp (one-minus-s-inverse * (ln (one-minus-s * x))) - 1.0
end

to log-log-histogram [unsorted-data increment]
  if empty? unsorted-data or increment <= 0 [stop]
  let data sort unsorted-data
  let low first data
  let high low + increment
  let max-index length data
  let index 0
  while [index < max-index]
    [let c 0
     let element item index data
     while [element >= low and element < high and index < max-index]
           [set c c + 1
            set index index + 1
            if index < max-index [set element item index data]]
     if c > 0
        [plotxy ln (low + increment / 2)
                ln c]
     set low high
     set high low + increment]
end

to run-in-observer-context [command]
  set observer-commands fput command observer-commands
end
@#$#@#$#@
GRAPHICS-WINDOW
5
5
829
398
-1
-1
4.0
1
10
1
1
1
0
1
1
1
0
203
0
95
0
0
1
time
30.0

CHOOSER
200
480
295
525
index-case
index-case
"Funston" "Etaples"
0

CHOOSER
400
480
495
525
view-who
view-who
"Infected" "Susceptibles" "Recovered" "Dead"
0

CHOOSER
300
480
395
525
history
history
"Historical" "No war" "War ends 1920"
0

MONITOR
500
480
600
533
Deaths
round the-global-dead 
0
1
13

MONITOR
605
480
705
533
Date
compute-date 
0
1
13

MONITOR
5
425
830
470
Area under mouse
patch-under-mouse-description 
0
1
11

PLOT
835
5
1200
235
Populations
Days since start until 1 Jan 1920
Population (powers of ten)
0.0
1000.0
0.0
10.0
false
true
"" ""
PENS
"a name never used" 1.0 0 -16777216 false "" ""

PLOT
835
240
1200
470
Daily Population Change
Days since start until 1 Jan 1920
People (log 10)
0.0
1000.0
0.0
8.0
false
true
"" ""
PENS
"a name never used" 1.0 0 -16777216 false "" ""

BUTTON
135
480
195
515
Reset
setup-only-if-needed (reset) 
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
5
480
65
515
Go
setup-only-if-needed (if reset-or-resume   [go])
T
1
T
OBSERVER
NIL
G
NIL
NIL
1

BUTTON
70
480
135
515
Pause
setup-only-if-needed (set stop-running true)
NIL
1
T
OBSERVER
NIL
.
NIL
NIL
1

OUTPUT
0
535
1200
583
12

@#$#@#$#@
WHAT IS IT?
-----------
This section could give a general understanding of what the model is trying to show or explain.


HOW IT WORKS
------------
This section could explain what rules the agents use to create the overall behavior of the model.


HOW TO USE IT
-------------
This section could explain how to use the model, including a description of each of the items in the interface tab.


THINGS TO NOTICE
----------------
This section could give some ideas of things for the user to notice while running the model.


THINGS TO TRY
-------------
This section could give some ideas of things for the user to try to do (move sliders, switches, etc.) with the model.


EXTENDING THE MODEL
-------------------
This section could give some ideas of things to add or change in the procedures tab to make the model more complicated, detailed, accurate, etc.


NETLOGO FEATURES
----------------
This section could point out any especially interesting or unusual features of NetLogo that the model makes use of, particularly in the Procedures tab.  It might also point out places where workarounds were needed because of missing features.


RELATED MODELS
--------------
This section could give the names of models in the NetLogo Models Library or elsewhere which are of related interest.


CREDITS AND REFERENCES
----------------------
This section could contain a reference to the model's URL on the web if it has one, as well as any other necessary credits or references.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

boat top
true
0
Polygon -7500403 true true 150 1 137 18 123 46 110 87 102 150 106 208 114 258 123 286 175 287 183 258 193 209 198 150 191 87 178 46 163 17
Rectangle -16777216 false false 129 92 170 178
Rectangle -16777216 false false 120 63 180 93
Rectangle -7500403 true true 133 89 165 165
Polygon -11221820 true false 150 60 105 105 150 90 195 105
Polygon -16777216 false false 150 60 105 105 150 90 195 105
Rectangle -16777216 false false 135 178 165 262
Polygon -16777216 false false 134 262 144 286 158 286 166 262
Line -16777216 false 129 149 171 149
Line -16777216 false 166 262 188 252
Line -16777216 false 134 262 112 252
Line -16777216 false 150 2 149 62

square
false
0
Rectangle -7500403 true true 30 30 270 270

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

train freight engine
false
0
Rectangle -7500403 true true 0 180 300 195
Polygon -7500403 true true 281 194 282 134 278 126 165 120 165 105 15 105 15 150 15 195 15 210 285 210
Polygon -955883 true false 281 179 263 150 225 150 15 150 15 135 270 135 282 148
Circle -16777216 true false 17 195 30
Circle -16777216 true false 50 195 30
Circle -16777216 true false 205 195 30
Circle -16777216 true false 238 195 30
Rectangle -7500403 true true 164 90 224 195
Rectangle -16777216 true false 176 98 214 120
Line -7500403 true 196 90 196 150
Rectangle -16777216 false false 165 90 225 180
Rectangle -16777216 false false 0 195 300 180
Rectangle -1 true false 11 111 18 118
Rectangle -1 true false 280 131 287 138
Rectangle -16777216 true false 91 195 201 212
Rectangle -16777216 true false 1 180 10 195
Line -16777216 false 290 150 291 182
Rectangle -7500403 true true 88 97 119 106
Rectangle -7500403 true true 42 96 73 105
Line -16777216 false 165 105 15 105
Rectangle -16777216 true false 165 90 195 90
Line -16777216 false 252 116 237 116
Rectangle -1184463 true false 199 85 208 92
Rectangle -16777216 true false 290 180 299 195
Line -16777216 false 224 98 165 98
@#$#@#$#@
NetLogo 6.3.0
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
