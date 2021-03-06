# Data sources

## EV chargepoints

The EV chargepoint dataset comes from the [National Chargepoint Registry](https://chargepoints.dft.gov.uk/) [CSV file](https://www.gov.uk/guidance/find-and-use-data-on-public-electric-vehicle-chargepoints) and appears to be released freely under OGL3. There are inconsistencies with the CSV file so it has to be pre-parsed to make the line breaks consistent.

The CSV (13MB) contains lat/lon as well as UPRN and lots of details about the charging point type, connectors, and access times. Note that of ~19,800 chargepoints included, around 50 obviously have the wrong coordinates. (UK)

  * chargeDeviceID
  * reference
  * name
  * latitude
  * longitude
  * subBuildingName
  * buildingName
  * buildingNumber
  * thoroughfare
  * street
  * doubleDependantLocality
  * dependantLocality
  * town
  * county
  * postcode
  * countryCode
  * uprn
  * deviceDescription
  * locationShortDescription
  * locationLongDescription
  * deviceManufacturer
  * deviceModel
  * deviceOwnerName
  * deviceOwnerWebsite
  * deviceOwnerTelephoneNo
  * deviceOwnerContactName
  * deviceControllerName
  * deviceControllerWebsite
  * deviceControllerTelephoneNo
  * deviceControllerContactName
  * deviceNetworks
  * chargeDeviceStatus
  * publishStatus
  * deviceValidated
  * dateCreated
  * dateUpdated
  * moderated
  * lastUpdated
  * lastUpdatedBy
  * attribution
  * dateDeleted
  * paymentRequired
  * paymentRequiredDetails
  * subscriptionRequired
  * subscriptionRequiredDetails
  * parkingFeesFlag
  * parkingFeesDetails
  * parkingFeesUrl
  * accessRestrictionFlag
  * accessRestrictionDetails
  * physicalRestrictionFlag
  * physicalRestrictionText
  * onStreetFlag
  * locationType
  * bearing
  * access24Hours
  * accessMondayFrom
  * accessMondayTo
  * accessTuesdayFrom
  * accessTuesdayTo
  * accessWednesdayFrom
  * accessWednesdayTo
  * accessThursdayFrom
  * accessThursdayTo
  * accessFridayFrom
  * accessFridayTo
  * accessSaturdayFrom
  * accessSaturdayTo
  * accessSundayFrom
  * accessSundayTo
  * connector1ID
  * connector1Type
  * connector1RatedOutputKW
  * connector1OutputCurrent
  * connector1RatedVoltage
  * connector1ChargeMethod
  * connector1ChargeMode
  * connector1TetheredCable
  * connector1Status
  * connector1Description
  * connector1Validated
  * connector2ID
  * connector2Type
  * connector2RatedOutputKW
  * connector2OutputCurrent
  * connector2RatedVoltage
  * connector2ChargeMethod
  * connector2ChargeMode
  * connector2TetheredCable
  * connector2Status
  * connector2Description
  * connector2Validated
  * connector3ID
  * connector3Type
  * connector3RatedOutputKW
  * connector3OutputCurrent
  * connector3RatedVoltage
  * connector3ChargeMethod
  * connector3ChargeMode
  * connector3TetheredCable
  * connector3Status
  * connector3Description
  * connector3Validated
  * connector4ID
  * connector4Type
  * connector4RatedOutputKW
  * connector4OutputCurrent
  * connector4RatedVoltage
  * connector4ChargeMethod
  * connector4ChargeMode
  * connector4TetheredCable
  * connector4Status
  * connector4Description
  * connector4Validated
  * connector5ID
  * connector5Type
  * connector5RatedOutputKW
  * connector5OutputCurrent
  * connector5RatedVoltage
  * connector5ChargeMethod
  * connector5ChargeMode
  * connector5TetheredCable
  * connector5Status
  * connector5Description
  * connector5Validated
  * connector6ID
  * connector6Type
  * connector6RatedOutputKW
  * connector6OutputCurrent
  * connector6RatedVoltage
  * connector6ChargeMethod
  * connector6ChargeMode
  * connector6TetheredCable
  * connector6Status
  * connector6Description
  * connector6Validated
  * connector7ID
  * connector7Type
  * connector7RatedOutputKW
  * connector7OutputCurrent
  * connector7RatedVoltage
  * connector7ChargeMethod
  * connector7ChargeMode
  * connector7TetheredCable
  * connector7Status
  * connector7Description
  * connector7Validated
  * connector8ID
  * connector8Type
  * connector8RatedOutputKW
  * connector8OutputCurrent
  * connector8RatedVoltage
  * connector8ChargeMethod
  * connector8ChargeMode
  * connector8TetheredCable
  * connector8Status
  * connector8Description
  * connector8Validated
  
Even limiting things to just a truncated ID and latitude and longitude takes up 540kB. For optimisation in the future we could think about splitting the CSV up into tiled chunks of data (perhaps like the GeoJSON chunks created for [osm-geojson](https://github.com/odileeds/osm-geojson/tree/master/tiles)) and an extract of JS from [osm.editor.js](https://odileeds.github.io/osmedit/resources/osm.editor.js).


## Supermarkets

These come from Open Street Map (ODbL).

## Car parks

These come from Open Street Map (ODbL).

