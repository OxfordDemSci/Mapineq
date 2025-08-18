
var viirsAnnual = ee.ImageCollection("NOAA/VIIRS/DNB/ANNUAL_V21"),
    viirsAnnual22 = ee.ImageCollection("NOAA/VIIRS/DNB/ANNUAL_V22"),
    nutsRegions2006 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/NUTS_RG_01M_2006_3035"),
    nutsRegions2003 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/NUTS_RG_01M_2003_3035"),
    nutsRegions2010 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/NUTS_RG_01M_2010_3035"),
    nutsRegions2013 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/NUTS_RG_01M_2013_3035"),
    nutsRegions2016 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/NUTS_RG_01M_2016_3035"),
    nutsRegions2021 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/NUTS_RG_01M_2021_3035"),
    nutsRegions2024 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/NUTS_RG_01M_2024_3035");


print('VIIRS 2022 Annual Collection:', viirsAnnual22);
print('VIIRS 2021 Annual Collection:', viirsAnnual);
print('Available bands:', viirsAnnual22.first().bandNames());

// Define NUTS versions
var nutsVersions = [
  {collection: nutsRegions2003, version: '2003'},
  {collection: nutsRegions2006, version: '2006'},
  {collection: nutsRegions2010, version: '2010'},
  {collection: nutsRegions2013, version: '2013'},
  {collection: nutsRegions2016, version: '2016'},
  {collection: nutsRegions2021, version: '2021'},
  {collection: nutsRegions2024, version: '2024'}
];

// Apply the function to each combination of year and NUTS version
var allStats = ee.FeatureCollection([]); // Empty to start

// -----------------  All year All nuts without geo: 2022 -------------------
// Define the years
var years = [2022, 2023, 2024];


// Function to compute stats for a given year and NUTS version
var getStatsForYearAndNUTS = function(year, nutsInfo) {
  var image = viirsAnnual22.filter(ee.Filter.calendarRange(year, year, 'year')).first();
  var rad = image.select('average_masked');

  var stats = rad.reduceRegions({
    collection: nutsInfo.collection,
    reducer: ee.Reducer.mean()
      .combine({reducer2: ee.Reducer.stdDev(), sharedInputs: true})
      .combine({reducer2: ee.Reducer.minMax(), sharedInputs: true}),
    scale: 500
  });

  // Create a new feature with only selected properties and no geometry
  return stats.map(function(f) {
    return ee.Feature(null, {
      'geo': f.get('NUTS_ID'),
      'mean': f.get('mean'),
      'stdDev': f.get('stdDev'),
      'max': f.get('max'),
      'obsTime': year,
      'geo_source': 'NUTS' + nutsInfo.version
    });
  });
};

// Apply the function to each combination of year and NUTS version
var allStats = ee.FeatureCollection([]); // Empty to start

years.forEach(function(year) {
  nutsVersions.forEach(function(nutsInfo) {
    var stats = getStatsForYearAndNUTS(year, nutsInfo);
    allStats = allStats.merge(stats);
  });
});

// Preview
print('Sample feature:', allStats.first());

// Export to Drive
Export.table.toDrive({
  collection: allStats,
  description: 'VIIRS_NUTS_All_22_24',
  fileFormat: 'CSV',
    selectors: ['geo', 'mean', 'stdDev', 'max', 'obsTime', 'geo_source']
});


// // -----------------  with 2 year All nuts without geo: 2021 -------------------
// // Take: 2h

// // Define the years
// var years = [2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021];

// // Define NUTS versions
// var nutsVersions = [
//   {collection: nutsRegions2003, version: '2003'},
//   {collection: nutsRegions2006, version: '2006'},
//   {collection: nutsRegions2010, version: '2010'},
//   {collection: nutsRegions2013, version: '2013'},
//   {collection: nutsRegions2016, version: '2016'},
//   {collection: nutsRegions2021, version: '2021'},
//   {collection: nutsRegions2024, version: '2024'}
// ];

// // Function to compute stats for a given year and NUTS version
// var getStatsForYearAndNUTS = function(year, nutsInfo) {
//   var image = viirsAnnual.filter(ee.Filter.calendarRange(year, year, 'year')).first();
//   var rad = image.select('average_masked');

//   var stats = rad.reduceRegions({
//     collection: nutsInfo.collection,
//     reducer: ee.Reducer.mean()
//       .combine({reducer2: ee.Reducer.stdDev(), sharedInputs: true})
//       .combine({reducer2: ee.Reducer.minMax(), sharedInputs: true}),
//     scale: 500
//   });

//   // Create a new feature with only selected properties and no geometry
//   return stats.map(function(f) {
//     return ee.Feature(null, {
//       'NUTS_ID': f.get('NUTS_ID'),
//       'mean': f.get('mean'),
//       'stdDev': f.get('stdDev'),
//       'max': f.get('max'),
//       'obsTime': year,
//       'geo_source': 'NUTS' + nutsInfo.version
//     });
//   });
// };

// // Apply the function to each combination of year and NUTS version
// var allStats = ee.FeatureCollection([]); // Empty to start

// years.forEach(function(year) {
//   nutsVersions.forEach(function(nutsInfo) {
//     var stats = getStatsForYearAndNUTS(year, nutsInfo);
//     allStats = allStats.merge(stats);
//   });
// });

// // Preview
// print('Sample feature:', allStats.first());

// // Export to Drive
// Export.table.toDrive({
//   collection: allStats,
//   description: 'VIIRS_NUTS_All_13_21',
//   fileFormat: 'CSV',
//     selectors: ['NUTS_ID', 'mean', 'stdDev', 'max', 'obsTime', 'geo_source']
// });


// -----------------  with 2 year All nuts with geo -------------------

// // Define the years
// var years = [2019, 2020, 2021];

// // Define NUTS versions
// var nutsVersions = [
//   {collection: nutsRegions2003, version: '2003'},
//   {collection: nutsRegions2006, version: '2006'},
//   {collection: nutsRegions2010, version: '2010'},
//   {collection: nutsRegions2013, version: '2013'},
//   {collection: nutsRegions2016, version: '2016'},
//   {collection: nutsRegions2021, version: '2021'},
//   {collection: nutsRegions2024, version: '2024'}
// ];

// // Function to compute stats for a given year and NUTS version
// var getStatsForYearAndNUTS = function(year, nutsInfo) {
//   var image = viirsAnnual.filter(ee.Filter.calendarRange(year, year, 'year')).first();
//   var rad = image.select('average_masked');

//   var stats = rad.reduceRegions({
//     collection: nutsInfo.collection,
//     reducer: ee.Reducer.mean()
//       .combine({reducer2: ee.Reducer.stdDev(), sharedInputs: true})
//       .combine({reducer2: ee.Reducer.minMax(), sharedInputs: true}),
//     scale: 500
//   });

//   // Add the year and NUTS version to each feature
//   return stats.map(function(f) {
//     return f.set({
//       'obsTime': year,
//       'geo_source': 'NUTS' + nutsInfo.version
//     });
//   });
// };

// // Apply the function to each combination of year and NUTS version
// var allStats = ee.FeatureCollection([]); // Empty to start

// years.forEach(function(year) {
//   nutsVersions.forEach(function(nutsInfo) {
//     var stats = getStatsForYearAndNUTS(year, nutsInfo);
//     allStats = allStats.merge(stats);
//   });
// });

// // Preview
// // print('Combined stats for 2020 & 2021 on NUTS 2003 & 2006:', allStats.limit(5));

// // Export to Drive
// Export.table.toDrive({
//   collection: allStats,
//   description: 'VIIRS_NUTS_All_19_21',
//   fileFormat: 'CSV'
// });

// // ----------------- 2 year -------------------
// // Define the years
// var years = [2020, 2021];

// // Function to compute stats for a single year
// var getStatsForYear = function(year) {
//   var image = viirsAnnual.filter(ee.Filter.calendarRange(year, year, 'year')).first();
//   var rad = image.select('average_masked');

//   var stats = rad.reduceRegions({
//     collection: nutsRegions2006,
//     reducer: ee.Reducer.mean()
//       .combine({reducer2: ee.Reducer.stdDev(), sharedInputs: true})
//       .combine({reducer2: ee.Reducer.minMax(), sharedInputs: true}),
//     scale: 500
//   });

//   // Add the year to each feature
//   return stats.map(function(f) {
//     return f.set('year', year);
//   });
// };

// // Apply the function to each year and merge
// var allStats = ee.FeatureCollection(getStatsForYear(2020))
//   .merge(getStatsForYear(2021));

// // Preview
// // print('Combined stats for 2020 & 2021:', allStats.limit(5));

// // Export
// Export.table.toDrive({
//   collection: allStats,
//   description: 'VIIRS_NUTS_2020_2021',
//   fileFormat: 'CSV'
// });



// // -----------------  with 1 year All nuts without geo -------------------
// // Define the years
// var year = 2022;

// print('VIIRS 2022 Annual Collection:', viirsAnnual22);
// print('VIIRS 2021 Annual Collection:', viirsAnnual);

// // Function to compute stats for 2022 (Different Dataset) across NUTS version
// var getStatsForYearAndNUTS = function(year, nutsInfo) {
//   var image = viirsAnnual22.filter(ee.Filter.calendarRange(year, year, 'year')).first();
//   var rad = image.select('average_masked');

//   var stats = rad.reduceRegions({
//     collection: nutsInfo.collection,
//     reducer: ee.Reducer.mean()
//       .combine({reducer2: ee.Reducer.stdDev(), sharedInputs: true})
//       .combine({reducer2: ee.Reducer.minMax(), sharedInputs: true}),
//     scale: 500
//   });

//   // Create a new feature with only selected properties and no geometry
//   return stats.map(function(f) {
//     return ee.Feature(null, {
//       'NUTS_ID': f.get('NUTS_ID'),
//       'mean': f.get('mean'),
//       'stdDev': f.get('stdDev'),
//       'max': f.get('max'),
//       'obsTime': year,
//       'geo_source': 'NUTS' + nutsInfo.version
//     });
//   });
// };

// nutsVersions.forEach(function(nutsInfo) {
//   var stats = getStatsForYearAndNUTS(year, nutsInfo);
//   allStats = allStats.merge(stats);
// });

// print('Sample feature:', allStats.first());

// Export.table.toDrive({
//   collection: allStats,
//   description: 'VIIRS_NUTS_OneYear_' + year,
//   fileFormat: 'CSV',
//   selectors: ['NUTS_ID', 'mean', 'stdDev', 'max', 'obsTime', 'geo_source']
// });



// // ----------------- 1 year 1 NUTS -------------------
// // Load one image to explore
// var image2020 = viirsAnnual.filter(ee.Filter.calendarRange(2020, 2020, 'year')).first();
// print('VIIRS 2020 image:', image2020);
// print('Available bands:', image2020.bandNames());

// var stats2020 = image2020.select('average_masked').reduceRegions({
//   collection: nutsRegions,
//   reducer: ee.Reducer.mean()
//     .combine({reducer2: ee.Reducer.stdDev(), sharedInputs: true})
//     .combine({reducer2: ee.Reducer.minMax(), sharedInputs: true}),
//   scale: 500
// }).map(function(f) {
//   return f.set('year', 2020);
// });

// print('Stats for 2020:', stats2020.limit(5)); // View first 5 features

// Export.table.toDrive({
//   collection: stats2020,
//   description: 'VIIRS_NUTS_2020_TestExport',
//   fileFormat: 'CSV'
// });


