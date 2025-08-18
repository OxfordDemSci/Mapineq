
var viirsAnnual = ee.ImageCollection("NOAA/VIIRS/DNB/ANNUAL_V21"),
    viirsAnnual22 = ee.ImageCollection("NOAA/VIIRS/DNB/ANNUAL_V22"),
    ITL_2021 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/itl_2021_BGC"),
    ITL_2025 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/itl_2025_BGC"),
    EURO_2021 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/EURO_2021_BGC"),
    EURO_2025 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/EURO_2025_BGC");


// print('Sample feature from ITL2021:', ITL_2025.first());
print('Sample feature from EURO_2021:', EURO_2021.first());
print('Sample feature from EURO_2021:', EURO_2021);
print('VIIRS 2022 Annual Collection:', viirsAnnual22);
print('VIIRS 2021 Annual Collection:', viirsAnnual);
print('Available bands:', viirsAnnual22.first().bandNames());

// ---------------------------- ITL ----------------------------

// // Define ITL versions
// var itlVersions = [
//   {collection: ITL_2021, version: '2021'},
//   {collection: ITL_2025, version: '2025'}
// ];

// // Apply the function to each combination of year and ITL version
// var allStats = ee.FeatureCollection([]); // Empty to start

// // -----------------  All year All ITL without geo: 2022 -------------------
// // Define the years
// var years = [2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021];
// // var years = [2022, 2023, 2024];

// // Function to compute stats for a given year and ITL version
// var getStatsForYearAndNUTS = function(year, itlInfo) {
//   var image = viirsAnnual.filter(ee.Filter.calendarRange(year, year, 'year')).first();
//   var rad = image.select('average_masked');

//   var stats = rad.reduceRegions({
//     collection: itlInfo.collection,
//     reducer: ee.Reducer.mean()
//       .combine({reducer2: ee.Reducer.stdDev(), sharedInputs: true})
//       .combine({reducer2: ee.Reducer.minMax(), sharedInputs: true}),
//     scale: 500
//   });

//   // Create a new feature with only selected properties and no geometry
//   return stats.map(function(f) {
//     return ee.Feature(null, {
//       'geo': f.get('ITL_CODE'),
//       'mean': f.get('mean'),
//       'stdDev': f.get('stdDev'),
//       'max': f.get('max'),
//       'obsTime': year,
//       'geo_source': 'ITL' + itlInfo.version
//     });
//   });
// };

// // Apply the function to each combination of year and ITL version
// var allStats = ee.FeatureCollection([]); // Empty to start

// years.forEach(function(year) {
//   itlVersions.forEach(function(itlInfo) {
//     var stats = getStatsForYearAndNUTS(year, itlInfo);
//     allStats = allStats.merge(stats);
//   });
// });

// // Preview
// print('Sample feature:', allStats.first());

// // Export to Drive
// Export.table.toDrive({
//   collection: allStats,
//   description: 'VIIRS_ITL_All_13_21',
//   fileFormat: 'CSV',
//     selectors: ['geo', 'mean', 'stdDev', 'max', 'obsTime', 'geo_source']
// });


// ---------------------------- EURO ----------------------------

// Define EURO versions
var euro_Versions = [
  {collection: EURO_2021, version: '2021'},
  {collection: EURO_2025, version: '2025'}
];

// Apply the function to each combination of year and EURO version
var allStats = ee.FeatureCollection([]); // Empty to start

// -----------------  All year All EURO without geo: 2022 -------------------
// Define the years
var years = [2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021];
// var years = [2022, 2023, 2024];

// Function to compute stats for a given year and EURO version
var getStatsForYearAndNUTS = function(year, euro_Info) {
  var image = viirsAnnual.filter(ee.Filter.calendarRange(year, year, 'year')).first();
  var rad = image.select('average_masked');

  var stats = rad.reduceRegions({
    collection: euro_Info.collection,
    reducer: ee.Reducer.mean()
      .combine({reducer2: ee.Reducer.stdDev(), sharedInputs: true})
      .combine({reducer2: ee.Reducer.minMax(), sharedInputs: true}),
    scale: 500
  });

  // Create a new feature with only selected properties and no geometry
  return stats.map(function(f) {
    return ee.Feature(null, {
      'geo': f.get('EURO_CODE'),
      'mean': f.get('mean'),
      'stdDev': f.get('stdDev'),
      'max': f.get('max'),
      'obsTime': year,
      'geo_source': 'EURO' + euro_Info.version
    });
  });
};

// Apply the function to each combination of year and EURO version
var allStats = ee.FeatureCollection([]); // Empty to start

years.forEach(function(year) {
  euro_Versions.forEach(function(euro_Info) {
    var stats = getStatsForYearAndNUTS(year, euro_Info);
    allStats = allStats.merge(stats);
  });
});

// Preview
print('Sample feature:', allStats.first());

// Export to Drive
Export.table.toDrive({
  collection: allStats,
  description: 'VIIRS_EURO_13_21',
  // description: 'VIIRS_EURO_22_24',
  fileFormat: 'CSV',
    selectors: ['geo', 'mean', 'stdDev', 'max', 'obsTime', 'geo_source']
});
