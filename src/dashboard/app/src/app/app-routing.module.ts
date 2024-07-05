import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { DashboardComponent } from './dashboard/dashboard.component';
import {DatacatalogueComponent} from "./datacatalogue/datacatalogue.component";

const routes: Routes = [
  { path: '', component: DashboardComponent },
  { path: 'case/:id', component: DashboardComponent },
  { path: 'case/:id/:variant', component: DashboardComponent },
  { path: 'datacatalogue', component: DatacatalogueComponent },
  { path: '**', component: DashboardComponent },

];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule { }
