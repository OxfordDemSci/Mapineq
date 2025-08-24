// Compute zonal stats for WorldClim Bioclimatic variables over NUTS regions
// using multiple NUTS versions


var nutsRegions2006 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/NUTS_RG_01M_2006_3035"),
    nutsRegions2003 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/NUTS_RG_01M_2003_3035"),
    nutsRegions2010 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/NUTS_RG_01M_2010_3035"),
    nutsRegions2013 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/NUTS_RG_01M_2013_3035"),
    nutsRegions2016 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/NUTS_RG_01M_2016_3035"),
    nutsRegions2021 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/NUTS_RG_01M_2021_3035"),
    nutsRegions2024 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/NUTS_RG_01M_2024_3035"),
    WC_Bio = ee.Image("WORLDCLIM/V1/BIO"),
    ITL_2021 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/itl_2021_BGC"),
    ITL_2025 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/itl_2025_BGC"),
    EURO_2021 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/EURO_2021_BGC"),
    EURO_2025 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/EURO_2025_BGC");



print('WC_Bio image:', WC_Bio);
print('WC_Bio Available bands:', WC_Bio.bandNames());

// // Define NUTS versions
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


// Function to compute stats for a NUTS version
var getStatsForNUTS = function(nutsInfo) {
  var stats = WC_Bio.reduceRegions({
    collection: nutsInfo.collection,
    reducer: ee.Reducer.mean()
              .combine({reducer2: ee.Reducer.minMax(), sharedInputs: true})
              .combine({reducer2: ee.Reducer.median(), sharedInputs: true})
              .combine({reducer2: ee.Reducer.stdDev(), sharedInputs: true})
              .combine({reducer2: ee.Reducer.percentile([10, 25, 75, 90]), sharedInputs: true}),
    scale: 200
  });

  // Annotate metadata and filter only required properties
  return stats.map(function(f) {
    return ee.Feature(null, f.toDictionary())  // remove geometry
      .set({
        'geo': f.get('NUTS_ID'),               // rename NUTS_ID to 'geo'
        // 'geo': f.get('ITL_CODE'),               // rename ITL_CODE to 'geo'
        // 'geo': f.get('EURO_CODE'),               // rename EURO_CODE to 'geo'
        'obsTime': '2000',
        'geo_source': 'NUTS' + nutsInfo.version
      });
  });
};

// Loop through all NUTS versions and merge results
var allBioStats = ee.FeatureCollection([]);

Versions.forEach(function(nutsInfo) {
  var stats = getStatsForNUTS(nutsInfo);
  allBioStats = allBioStats.merge(stats);
});

// Preview
print('WC_Bio Zonal Stats (Stripped Down):', allBioStats.limit(5));

// Export to CSV (no geometry)
Export.table.toDrive({
  collection: allBioStats,
  description: 'WC_Bio_AllBands_NUTS',
  fileFormat: 'CSV'
});


// code above optimise the columns

// // Function to compute stats for a NUTS version
// var getStatsForNUTS = function(nutsInfo) {
//   var stats = WC_Bio.reduceRegions({
//     collection: nutsInfo.collection,
//     reducer: ee.Reducer.mean()
//               .combine({reducer2: ee.Reducer.max(), sharedInputs: true})
//               .combine({reducer2: ee.Reducer.median(), sharedInputs: true})
//               .combine({reducer2: ee.Reducer.stdDev(), sharedInputs: true}),
//     scale: 1000 // Adjust this if needed
//   });

//   // Annotate metadata
//   return stats.map(function(f) {
//     return f.set({
//       'obsTime': '1950-2000',
//       'geo_source': 'NUTS' + nutsInfo.version
//     });
//   });
// };

// // Loop through all NUTS versions and merge results
// var allBioStats = ee.FeatureCollection([]);

// Versions.forEach(function(nutsInfo) {
//   var stats = getStatsForNUTS(nutsInfo);
//   allBioStats = allBioStats.merge(stats);
// });

// // Preview a few results
// print('WC_Bio Zonal Stats (All Bands):', allBioStats.limit(5));

// // Export as CSV
// Export.table.toDrive({
//   collection: allBioStats,
//   description: 'WC_Bio_AllBands_Stats',
//   fileFormat: 'CSV'
// });
