var nutsRegions2006 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/NUTS_RG_01M_2006_3035"),
    nutsRegions2003 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/NUTS_RG_01M_2003_3035"),
    nutsRegions2010 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/NUTS_RG_01M_2010_3035"),
    nutsRegions2013 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/NUTS_RG_01M_2013_3035"),
    nutsRegions2016 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/NUTS_RG_01M_2016_3035"),
    nutsRegions2021 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/NUTS_RG_01M_2021_3035"),
    nutsRegions2024 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/NUTS_RG_01M_2024_3035"),
    viirsMonthStrayLight = ee.ImageCollection("NOAA/VIIRS/DNB/MONTHLY_V1/VCMSLCFG"),
    viirsMonthly = ee.ImageCollection("NOAA/VIIRS/DNB/MONTHLY_V1/VCMCFG");



    
print('VIIRS Month Stray Lightl Collection:', viirsMonthStrayLight);
print('Available bands:', viirsMonthStrayLight.first().bandNames());
// https://developers.google.com/earth-engine/datasets/catalog/NOAA_VIIRS_DNB_MONTHLY_V1_VCMSLCFG

print('VIIRS Month Collection:', viirsMonthly);
print('Available bands:', viirsMonthly.first().bandNames());
// https://developers.google.com/earth-engine/datasets/catalog/NOAA_VIIRS_DNB_MONTHLY_V1_VCMCFG

// Define NUTS versions
var nutsVersions = [
  {collection: nutsRegions2003, version: '2003'},
  {collection: nutsRegions2006, version: '2006'},
  {collection: nutsRegions2010, version: '2010'},
  {collection: nutsRegions2013, version: '2013'},
  {collection: nutsRegions2016, version: '2016'},
  {collection: nutsRegions2021, version: '2021'},
  {collection: nutsRegions2024, version: '2024'}];

// !!!!!!!!!!!!!!!!!!!!!!!!! 2024 11 is missing for StrayLight !!!!!!!!!!!!!!!!!!!!!!!!!!!
// // -----------------  All year All nuts without geo: 2022 -------------------
// Define the years and months
// var years = [2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024];
// var years = [2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023]; 
// var years = [2012];
var years = [2025];

// var months = ee.List.sequence(1, 12);
var months = ee.List.sequence(1, 3);

// Function to get monthly stats for a given year, month, and NUTS version
var getMonthlyStats = function(year, month, nutsInfo) {
  var filtered = viirsMonthly
  // var filtered = viirsMonthStrayLight
    .filter(ee.Filter.calendarRange(year, year, 'year'))
    .filter(ee.Filter.calendarRange(month, month, 'month'));

  var image = ee.Image(filtered.first());
  var rad = image.select('avg_rad'); // Main radiance band

  var stats = rad.reduceRegions({
    collection: nutsInfo.collection,
    reducer: ee.Reducer.mean()
      .combine({reducer2: ee.Reducer.stdDev(), sharedInputs: true})
      .combine({reducer2: ee.Reducer.minMax(), sharedInputs: true}),
    scale: 500
  });

  return stats.map(function(f) {
    return ee.Feature(null, {
      'geo': f.get('NUTS_ID'),
      'mean': f.get('mean'),
      'std_dev': f.get('stdDev'),
      'max': f.get('max'),
      'obsTime': year,
      'obsMonth': month,
      'geo_source': 'NUTS' + nutsInfo.version
    });
  });
};

// Initialize empty FeatureCollection
var allMonthlyStats = ee.FeatureCollection([]);

// Loop over all years, months, and NUTS versions
years.forEach(function(year) {
  months.getInfo().forEach(function(month) {
    nutsVersions.forEach(function(nutsInfo) {
      var stats = getMonthlyStats(year, month, nutsInfo);
      allMonthlyStats = allMonthlyStats.merge(stats);
    });
  });
});

// Preview result
print('Sample monthly feature:', allMonthlyStats.first());

// Export to Drive
Export.table.toDrive({
  collection: allMonthlyStats,
  description: 'VIIRS_NUTS_Monthly_25',
  // description: 'VIIRS_NUTS_Monthly_straylight_2025',
  fileFormat: 'CSV',
  selectors: ['geo', 'mean', 'std_dev', 'max', 'obsTime', 'obsMonth', 'geo_source']
});


// // -----------------  All year All nuts without geo: 2022 -------------------
// // Define the years
// var years = [2022, 2023, 2024];


// // Function to compute stats for a given year and NUTS version
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
//   description: 'VIIRS_NUTS_All_22_24',
//   fileFormat: 'CSV',
//     selectors: ['NUTS_ID', 'mean', 'stdDev', 'max', 'obsTime', 'geo_source']
// });