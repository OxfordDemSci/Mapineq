# APP

---


Stappen voor Angular start: `npm install -g @angular/cli`

en dan:

`ng new app --no-standalone`

~~`Would you like to add Angular routing?` **y**~~ vraag wordt niet meer gesteld ...

`Which stylesheet format would you like to use? (Use arrow keys)` **CSS**

(nieuw:)<br>
`Do you want to enable Server-Side Rendering (SSR) and Static Site Generation (SSG/Prerendering)? (y/N)` **N**  ---  _DIT WILLEN WE **NIET**!!!_

daarna:

`cd app`

---

---



#### Additionele NPM en NG installaties:

* pas `app.component.ts` aan:
    ```
    export class AppComponent {
      title = 'HIER DE TITEL DIE JE DE APP WILT GEVEN';
    }
    ```
* pas `index.html` aan:
    ```
    <title>HIER DE TITEL DIE JE DE APP WILT GEVEN</title>  
    ```

* vul `package.json` de _**scripts**_ aan met:
  ````
  "start + browser": "ng serve --open",
  "build-prod ROOT": "node update_app_version_and_build.js  &&  ng build --configuration production",
  "build-prod + base=href": "node update_app_version_and_build.js  &&  ng build --configuration production --base-href /dashboard/",
  ````
_NB volgende stappen vanuit directory `app/`, dus een map dieper dan waar deze readme staat._

* `npm install --save @angular/material @angular/cdk @angular/animations`

* `ng add @angular/pwa` (op vraag over proceed **y** antwoorden)

* deze stap is niet nodig ~~als je bij eerste vraag van angular installatie (over routing) _y_ hebt geantwoord, _NB vraag wordt eerder niet meer gesteld in eerdere stap_~~:

  ~~`ng generate module app-routing --flat --module=app`~~  // https://angular.io/tutorial/toh-pt5

  Daarna (wel) ook app-routing.module.ts aanpassen, zie **BLOK1** t/m **BLOK3** hieronder!

* `ng add @angular/material` // kies _custom_, _y_ en bij vraag Include the Angular animations module? kies je _'Include and enable animations'_ (bovenste keuze), pas vervolgens custom-theme.scss aan zie **BLOK4** hieronder

* `ng generate component dashboard`



* inhoud van `app-routing.module.ts`:
  ```
  **BLOK1**
  import { NgModule } from '@angular/core';
  import { RouterModule, Routes } from '@angular/router';
  import { DashboardComponent } from './dashboard/dashboard.component';

  const routes: Routes = [
    { path: '', component: DashboardComponent },
    // { path: 'map', component: MapComponent }
    { path: '**', component: DashboardComponent }
  ];
  
  @NgModule({
    imports: [RouterModule.forRoot(routes)],
    exports: [RouterModule]
  })
  export class AppRoutingModule { }
  ```

* inhoud van `app.component.html`:
  ```
  **BLOK2**
  <mat-toolbar color="primary" class="app-toolbar">
    <mat-toolbar-row>
      <button mat-icon-button [matMenuTriggerFor]="menu" aria-label="Example icon-button with a menu">
        <mat-icon>more_vert</mat-icon>
      </button>
      <span>{{title}}</span>
      <span class="example-fill-remaining-space"></span>
    </mat-toolbar-row>
  </mat-toolbar>
  <mat-menu #menu="matMenu" color="primary">
    <button mat-menu-item routerLink="/">
      <mat-icon>home</mat-icon>
      Home
    </button>
  </mat-menu><router-outlet></router-outlet>
  <!--
  <app-messages></app-messages>
  -->
  ```

* voeg in `app.module.ts` de volgende modules toe aan de _imports_-array en zorg dat ze bovenaan script ook daadwerkelijk allemaal geimporteerd worden:
  ```
  **BLOK3**
      MatToolbarModule, 
      MatMenuModule, 
      MatIconModule, 
      MatButtonModule
  ```

* voeg in `custom-theme.scss` de volgende code toe/vervang waar van toepassing:
  ```
  **BLOK4**

  // VOOR @include mat.core()
  @include mat.all-component-typographies();


  // NA @include mat-core(); de onderstaande code tot aan '(...)'
  // https://maketintsandshades.com/#00c0ff
  // https://maketintsandshades.com/#003e5b

  $mat-cust: (
    50: #e6ecef,
    100: #ccd8de,
    200: #b3c5ce,
    300: #99b2bd,
    400: #809fad,
    500: #668b9d,
    600: #4d788c,
    700: #33657c,
    800: #1a516b,
    900: #003e5b,
    A100: #e6ecef, // 50
    A200: #99b2bd, // 300
    A400: #4d788c, // 600
    A700: #003e5b, // 900
    WARN: #DD2222,
    contrast: (
      50: black,
      100: black,
      200: black,
      300: black,
      400: black,
      500: white,
      600: white,
      700: white,
      800: white,
      900: white,
      A100: black,
      A200: black,
      A400: white,
      A700: white,
      WARN: white
    )
  );  
  (...)
  // $app-primary: mat.define-palette(mat.$indigo-palette);
  // $app-accent: mat.define-palette(mat.$pink-palette, A200, A100, A400);
  $app-primary: mat.define-palette($mat-cust, 900);
  $app-accent: mat.define-palette($mat-cust, 200);
  
  (...)
  // $app-warn: mat.define-palette(mat.$red-palette);
  $app-warn: mat.define-palette($mat-cust, WARN);    
  ```
* Pas `index.html` aan:
  ```
  **BLOK5**
  // Na '<meta name="viewport" ...>'
  
  <!--link rel="icon" type="image/x-icon" href="favicon.ico"-->
  <link rel="icon" href="assets/icons/icon-32x32.png" sizes="32x32" />
  <link rel="icon" href="assets/icons/icon-192x192.png" sizes="192x192" />
  <link rel="apple-touch-icon-precomposed" href="assets/icons/icon-180x180.png" />
  <link rel="apple-touch-icon" href="assets/icons/icon-192x192.png">
  <meta name="msapplication-TileImage" content="assets/icons/icon-270x270.png" />

      
  <link rel="manifest" href="manifest.webmanifest">
  <meta name="theme-color" content="#00c0ff">

  <!--
  <link rel="preconnect" href="https://fonts.gstatic.com">
  <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@300;400;500&display=swap" rel="stylesheet">
  <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
  -->
  ```

* Pas `manifest.webmanifest` aan:
    ```
    **BLOK6**
      "name": "HIER DE (lange) TITEL DIE JE DE APP WILT GEVEN",
      "short_name": "HIER DE (korte) TITEL",
      "theme_color": "#003e5b",
      "background_color": "#ffffff",
    ```


* Pas `tsconfig.json` aan // https://stackoverflow.com/questions/49699067/property-has-no-initializer-and-is-not-definitely-assigned-in-the-construc
    ```
    // voeg toe NA ' "strict": true, '
       "strictPropertyInitialization": false,

    // voeg toe NA ' "noImplicitReturns": true, '
       "noImplicitAny": false,
       "strictNullChecks": false,
    ```


* **Fonts**
  * Material design font:<br>
    ~~npm install material-design-icons   // https://github.com/angular/angular-cli/issues/2662~~

    `npm install material-icons --save` // https://www.npmjs.com/package/material-icons#available-icons

  * Roboto:<br>
    `npm install roboto-fontface`         // https://stackoverflow.com/questions/51687257/how-to-add-google-fonts-library-with-angular-6

  * in `angular.json` aan styles toevoegen? tussen `"src/custom-theme.scss",` en `"src/styles.css"`

    ~~"../node_modules/material-design-icons/iconfont/material-icons.css",~~
    ``` 
      "node_modules/material-icons/iconfont/material-icons.css",
      "node_modules/roboto-fontface/css/roboto/roboto-fontface.css",
    ```
    * PROBLEMEN met updaten / publiceren van icons naar NPM (daarom staat hierboven eea doorgestreept): <br>
      https://github.com/google/material-design-icons/issues/1050 (duidelijke discussie)<br>
      https://github.com/google/material-design-icons/issues/1129 (vermelding mogelijke oplossing, recent)<br>
      oplossing:<br>
      https://www.npmjs.com/package/material-icons#available-icons



* **Build budgets**
  * Pas budgets "initial" aan zodat er geen foutmelding komt tijdens builden voor productie. In `angular.json` moet je het volgende aanpassen:
    * `500kb` in `2mb`
    * `1mb` in `5mb`
    ```
      "budgets": [
        {
          "type": "initial",
          "maximumWarning": "500kb",
          "maximumError": "1mb"
        },
    ```
    wordt dan dus:
    ```
      "budgets": [
        {
          "type": "initial",
          "maximumWarning": "2mb",
          "maximumError": "5mb"
        },
    ```



  ---


<!--
## OpenLayers

* `ng generate component map` (add to app-routing.module.ts)
* * `npm install --save ol`
* voeg `"node_modules/ol/ol.css",` toe aan styles-array in _angular.json_
* voeg onderstaande toe aan _map.component.html_
  ````
  <div id="ol-map" class="map-container"></div>
  ````
* voeg onderstaande toe aan _map.component.css_
  ````
  .map-container {
    height: var(--page-content-height);
  }
  ````
* Vervang code van _map.component.ts_ met:
  ````
  import {AfterViewInit, Component, OnInit} from '@angular/core';
  import Map from 'ol/Map';
  import View from 'ol/View';
  import TileLayer from 'ol/layer/Tile';
  import OSM from 'ol/source/OSM';
  
  @Component({
    selector: 'app-map',
    templateUrl: './map.component.html',
    styleUrls: ['./map.component.css']
  })
  export class MapComponent implements OnInit, AfterViewInit {
  
    map: Map;
  
  
    constructor() { }
    
    ngOnInit(): void {
    } // END ngOnInit
    
    ngAfterViewInit(): void {
      this.map = new Map({
        view: new View({
          center: [0, 0],
          zoom: 1,
        }),
        layers: [
          new TileLayer({
            source: new OSM(),
          }),
        ],
        target: 'ol-map'
      });
    } // END ngAfterViewInit
    
  }
  ````

* `npm install geojson`
* `npm install --save-dev @types/geojson`




* **Proj4**
  * `npm install proj4` // http://proj4js.org/
  * `npm install --save-dev @types/proj4`

-->







---

---

---

<!--
SCANNEN NOG NIET GEIMPLEMENTEERD (Sjoerd)
* ***Scan***

  * ngx-scanner: https://github.com/zxing-js/ngx-scanner
  * getting started stappen: https://github.com/zxing-js/ngx-scanner/wiki/Getting-Started
    * ```
    npm i @zxing/browser@latest --save
    npm i @zxing/library@latest --save
    npm i @zxing/ngx-scanner@latest --save
    ```


--
-->

<!-- -->
* ***Leaflet***

  * `npm install leaflet`
  * `npm install --save-dev @types/leaflet`


* ***overige (Leaflet)***
  * Mogelijk geeft eerste optie hieronder foutmelding, dan tweede (b.) proberen: 
    1. `@import "~leaflet/dist/leaflet.css";` toevoegen aan styles.css
    2. in `angular.json` aan styles toevoegen? tussen `"node_modules/roboto-fontface/css/roboto/roboto-fontface.css",` en `"src/styles.css"`

      ``` 
        "node_modules/leaflet/dist/leaflet.css",
        "node_modules/material-icons/iconfont/material-icons.css",
        "node_modules/roboto-fontface/css/roboto/roboto-fontface.css",
      ```  
  * toevoegen aan `angular.json` tussen "src/assets", en "src/manifest.webmanifest":
    ```
              {
                "glob": "**/*",
                "input": "node_modules/leaflet/dist/images/",
                "output": "./assets"
              },
    ```


<!--

* ***Proj4 / Proj4Leaflet***
  * `npm install proj4` // http://proj4js.org/
  * `npm install --save-dev @types/proj4`
  * `npm install --save proj4leaflet` // https://kartena.github.io/Proj4Leaflet/
  * `npm install --save-dev @types/proj4leaflet`

!-- -->

<!-- --
* **leaflet-textpath**
  * `npm install leaflet-textpath`
  * `import 'leaflet-textpath';` bovenaan je script
  * https://www.npmjs.com/package/leaflet-textpath voor voorbeeldgebruik
!-- -->


<!-- --
* **Leaflet custom control/buttons**
  * Plaatsen `leaflet-control-custom.ts` in `/src/app/lib/`
!-- -->

--- 






---

---

---

