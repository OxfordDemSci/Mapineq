import {NgModule, isDevMode} from '@angular/core';
import {BrowserModule} from '@angular/platform-browser';

import {AppRoutingModule} from './app-routing.module';
import {AppComponent} from './app.component';
import {ServiceWorkerModule} from '@angular/service-worker';
import {DashboardComponent} from './dashboard/dashboard.component';
import {MatToolbarModule} from "@angular/material/toolbar";
import {MatMenuModule} from "@angular/material/menu";
import {MatIconModule} from "@angular/material/icon";
import {MatButtonModule} from "@angular/material/button";
import { provideAnimationsAsync } from '@angular/platform-browser/animations/async';
import { SelectTableValueComponent } from './select-table-value/select-table-value.component';
import {MatCardModule} from "@angular/material/card";
import {MatInputModule} from "@angular/material/input";
import {MatOptionModule} from "@angular/material/core";
import {MatSelectModule} from "@angular/material/select";
import {provideHttpClient} from "@angular/common/http";
import {MatSidenavModule} from "@angular/material/sidenav";
import { ResultMapComponent } from './result-map/result-map.component';
import {MatAutocompleteModule} from "@angular/material/autocomplete";
import {FormsModule, ReactiveFormsModule} from "@angular/forms";
import {MatFormFieldModule} from "@angular/material/form-field";
import { GraphComponent } from './graph/graph.component';
import {NgForOf, NgOptimizedImage} from "@angular/common";
import { DatacatalogueComponent } from './datacatalogue/datacatalogue.component';
import {MatGridList, MatGridTile} from "@angular/material/grid-list";
import {MatDivider} from "@angular/material/divider";
import {MatTooltipModule} from "@angular/material/tooltip";
import {DialogAppVersionAndBuildInfo} from "./lib/dialog-app-version-and-build-info.component";
import {MatDialogModule} from "@angular/material/dialog";


@NgModule({
    declarations: [
        AppComponent,
        DashboardComponent,
        SelectTableValueComponent,
        ResultMapComponent,
        GraphComponent,
        DatacatalogueComponent,
        DialogAppVersionAndBuildInfo
    ],
    imports: [
        BrowserModule,
        AppRoutingModule,
        MatToolbarModule,
        MatMenuModule,
        MatIconModule,
        MatButtonModule,
        MatCardModule,
        MatSidenavModule,
        ServiceWorkerModule.register('ngsw-worker.js', {
            enabled: !isDevMode(),
            // Register the ServiceWorker as soon as the application is stable
            // or after 30 seconds (whichever comes first).
            registrationStrategy: 'registerWhenStable:30000'
        }),
        MatInputModule,
        MatOptionModule,
        MatSelectModule,
        MatAutocompleteModule,
        MatFormFieldModule,
        ReactiveFormsModule,
        FormsModule,
        MatIconModule,
        NgForOf,
        NgOptimizedImage,
        MatGridList,
        MatGridTile,
        MatDivider,
        MatTooltipModule,
        MatDialogModule
    ],
    providers: [
    provideAnimationsAsync(), provideHttpClient()
  ],
    bootstrap: [AppComponent]
})
export class AppModule {
}
