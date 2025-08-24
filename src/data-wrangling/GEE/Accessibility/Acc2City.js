var nutsRegions2006 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/NUTS_RG_01M_2006_3035"),
    nutsRegions2003 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/NUTS_RG_01M_2003_3035"),
    nutsRegions2010 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/NUTS_RG_01M_2010_3035"),
    nutsRegions2013 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/NUTS_RG_01M_2013_3035"),
    nutsRegions2016 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/NUTS_RG_01M_2016_3035"),
    nutsRegions2021 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/NUTS_RG_01M_2021_3035"),
    nutsRegions2024 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/NUTS_RG_01M_2024_3035"),
    EURO_2021 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/EURO_2021_BGC"),
    EURO_2025 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/EURO_2025_BGC"),
    ITL_2021 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/itl_2021_BGC"),
    ITL_2025 = ee.FeatureCollection("projects/zhangwl54/assets/Mapineq/itl_2025_BGC"),
    dataset = ee.Image("Oxford/MAP/accessibility_to_cities_2015_v1_0");


var accessibility = dataset.select('accessibility');
var accessibilityVis = {
  min: 0.0,
  max: 41556.0,
  gamma: 4.0,
};
Map.setCenter(18.98, 6.66, 2);
Map.addLayer(accessibility, accessibilityVis, 'Accessibility');

print('accessibility 2015 image:', dataset);
print('accessibility 2015 Available bands:', dataset.bandNames());


print(nutsRegions2006.limit(5));
print(ITL_2021.limit(5));
print(EURO_2021.limit(5));

// Define NUTS versions
// var nutsVersions = [
//   {collection: nutsRegions2003, version: '2003'},
//   {collection: nutsRegions2006, version: '2006'},
//   {collection: nutsRegions2010, version: '2010'},
//   {collection: nutsRegions2013, version: '2013'},
//   {collection: nutsRegions2016, version: '2016'},
//   {collection: nutsRegions2021, version: '2021'},
//   {collection: nutsRegions2024, version: '2024'}
// ];

// var itlVersions = [
//   {collection: ITL_2021, version: '2021'},
//   {collection: ITL_2025, version: '2025'}
// ];

var euroVersions = [
  {collection: EURO_2021, version: '2021'},
  {collection: EURO_2025, version: '2025'}
];

// Function to compute zonal statistics per NUTS version
var getStatsForNUTS = function(nutsInfo) {
  // Keep only NUTS_ID and geometry from the original input
  var base = nutsInfo.collection.map(function(f) {
    return ee.Feature(f.geometry())
      // .set('geo', f.get('NUTS_ID'));
      // .set('geo', f.get('ITL_CODE'));
      .set('geo', f.get('EURO_CODE'));
  });

  // Reduce accessibility image over those features
  var stats = accessibility.reduceRegions({
    collection: base,
    reducer: ee.Reducer.mean()
              .combine({reducer2: ee.Reducer.max(), sharedInputs: true})
              .combine({reducer2: ee.Reducer.median(), sharedInputs: true})
              .combine({reducer2: ee.Reducer.stdDev(), sharedInputs: true}),
    scale: 1000,
    crs: 'EPSG:4326'
  });

  // Add time and source metadata
  return stats.map(function(f) {
    return f.set({
      'obsTime': '2015',
      // 'geo_source': 'NUTS' + nutsInfo.version
      // 'geo_source': 'ITL' + nutsInfo.version
      'geo_source': 'EURO' + nutsInfo.version
    });
  });
};


// Merge all zonal stats
var allAccessibilityStats = ee.FeatureCollection([]);
// nutsVersions.forEach(function(nutsInfo) {
// itlVersions.forEach(function(nutsInfo) {
euroVersions.forEach(function(nutsInfo) {
  var stats = getStatsForNUTS(nutsInfo);
  allAccessibilityStats = allAccessibilityStats.merge(stats);
});

// Preview output
print('Accessibility Zonal Stats:', allAccessibilityStats.limit(5));

// Export to CSV
Export.table.toDrive({
  collection: allAccessibilityStats,
  description: 'Accessibility_Zonal_EURO',
  fileFormat: 'CSV'
});

