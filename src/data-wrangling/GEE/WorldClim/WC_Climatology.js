// Compute zonal stats for WorldClim Bioclimatic variables over NUTS regions
// using multiple NUTS versions

var nutsRegions2006 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/NUTS_RG_01M_2006_3035"),
    nutsRegions2003 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/NUTS_RG_01M_2003_3035"),
    nutsRegions2010 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/NUTS_RG_01M_2010_3035"),
    nutsRegions2013 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/NUTS_RG_01M_2013_3035"),
    nutsRegions2016 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/NUTS_RG_01M_2016_3035"),
    nutsRegions2021 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/NUTS_RG_01M_2021_3035"),
    nutsRegions2024 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/NUTS_RG_01M_2024_3035"),
    WC_Climatology = ee.ImageCollection("WORLDCLIM/V1/MONTHLY"),
    ITL_2021 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/itl_2021_BGC"),
    ITL_2025 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/itl_2025_BGC"),
    EURO_2021 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/EURO_2021_BGC"),
    EURO_2025 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/EURO_2025_BGC");


print('WC_Climatology:', WC_Climatology);
print('WC_Climatology Available bands:', WC_Climatology.first().bandNames());

// Define NUTS versions
var Versions = [
  {collection: nutsRegions2003, version: '2003'},
  {collection: nutsRegions2006, version: '2006'},
  {collection: nutsRegions2010, version: '2010'},
  {collection: nutsRegions2013, version: '2013'},
  {collection: nutsRegions2016, version: '2016'},
  {collection: nutsRegions2021, version: '2021'},
  {collection: nutsRegions2024, version: '2024'}
];

// // Define ITL versions
// var Versions = [
//   {collection: ITL_2021, version: '2021'},
//   {collection: ITL_2025, version: '2025'}
// ];

// // Define EURO versions
// var Versions = [
//   {collection: EURO_2021, version: '2021'},
//   {collection: EURO_2025, version: '2025'}
// ];


// Function to compute stats for a given image, month, and nuts version
var reduceImageForNUTS = function(image, monthStr, nutsInfo) {
  var stats = image.reduceRegions({
    collection: nutsInfo.collection,
    reducer: ee.Reducer.mean()
              .combine({reducer2: ee.Reducer.minMax(), sharedInputs: true})
              .combine({reducer2: ee.Reducer.median(), sharedInputs: true})
              .combine({reducer2: ee.Reducer.stdDev(), sharedInputs: true})
              .combine({reducer2: ee.Reducer.percentile([10, 25, 75, 90]), sharedInputs: true}),
    scale: 200
  });

  // Remove geometry and keep only NUTS_ID (renamed to 'geo')
  return stats.map(function(f) {
    return ee.Feature(null, f.toDictionary())  // remove geometry
      .set({
        // 'geo': f.get('ITL_CODE'),               // rename ITL_CODE to 'geo'
        // 'geo': f.get('EURO_CODE'),               // rename EURO_CODE to 'geo'
        'geo': f.get('NUTS_ID'),               // rename NUTS_ID to 'geo'
        'month': monthStr,
        'geo_source': 'NUTS' + nutsInfo.version
      });
  });
};

// Function to process one month
var processMonth = function(monthIndex, image, allStats) {
  var monthNumber = ee.Number(monthIndex).add(1);
  var monthStr = monthNumber.format('%02d');

  Versions.forEach(function(nutsInfo) {
    var stats = reduceImageForNUTS(image, monthStr, nutsInfo);
    allStats = allStats.merge(stats);
  });

  return allStats;
};

// Start empty collection
var allMonthlyStats = ee.FeatureCollection([]);

// Get 12 images from the ImageCollection (Jan–Dec)
var monthlyList = WC_Climatology.sort('month').toList(12);

// Loop over months
for (var i = 0; i < 12; i++) {
  var image = ee.Image(monthlyList.get(i));
  allMonthlyStats = processMonth(i, image, allMonthlyStats);
}

// Preview results
print('WC_Climatology Zonal Stats (No Geometry):', allMonthlyStats.limit(5));

// Export to CSV without geometry
Export.table.toDrive({
  collection: allMonthlyStats,
  description: 'WC_Climatology_NUTS',
  fileFormat: 'CSV'
});


// // Function to compute stats for a given image, month, and nuts version
// var reduceImageForNUTS = function(image, monthStr, nutsInfo) {
//   var stats = image.reduceRegions({
//     collection: nutsInfo.collection,
//     reducer: ee.Reducer.mean()
//               .combine({reducer2: ee.Reducer.stdDev(), sharedInputs: true}),
//     scale: 1000
//   });

//   return stats.map(function(f) {
//     return f.set({
//       'month': monthStr,
//       'geo_source': 'NUTS' + nutsInfo.version
//     });
//   });
// };

// // Function to process one month (moved outside the loop!)
// var processMonth = function(monthIndex, image, allStats) {
//   var monthNumber = ee.Number(monthIndex).add(1);
//   var monthStr = monthNumber.format('%02d');

//   Versions.forEach(function(nutsInfo) {
//     var stats = reduceImageForNUTS(image, monthStr, nutsInfo);
//     allStats = allStats.merge(stats);
//   });

//   return allStats;
// };

// // Start empty collection
// var allMonthlyStats = ee.FeatureCollection([]);

// // Get 12 images from the ImageCollection
// var monthlyList = WC_Climatology.sort('month').toList(12);

// // Loop over 12 months without defining functions inside
// for (var i = 0; i < 12; i++) {
//   var image = ee.Image(monthlyList.get(i));
//   allMonthlyStats = processMonth(i, image, allMonthlyStats);
// }

// // Preview
// print('WC_Monthly Stats Per Month and Region:', allMonthlyStats.limit(5));

// // Export to CSV
// Export.table.toDrive({
//   collection: allMonthlyStats,
//   description: 'WC_Monthly_AllMonths_Stats',
//   fileFormat: 'CSV'
// });
