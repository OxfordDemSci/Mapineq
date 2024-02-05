import { Routes } from '@angular/router';
import {HomeComponent} from "./home/home.component";
import {InfoComponent} from "./info/info.component";

export const routes: Routes = [
  { path: '', component: HomeComponent },
  // { path: 'map', component: MapComponent }
  { path: 'info', component: InfoComponent },
  { path: '**', component: HomeComponent }
];
