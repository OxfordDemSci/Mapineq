import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { DashboardComponent } from './dashboard/dashboard.component';
import {DatacatalogueComponent} from "./datacatalogue/datacatalogue.component";

const routes: Routes = [
  { path: '', component: DashboardComponent },
  { path: 'case/:case', component: DashboardComponent },
  { path: 'case/:case/:variant', component: DashboardComponent },
  // { path: 'load/:table/:minlevel/:maxlevel', component: DashboardComponent },
  { path: 'load/:table', component: DashboardComponent },
  { path: 'datacatalogue', component: DatacatalogueComponent },
  /*
  {
    path: 'datacatalogue',
    redirectTo: '/mapineq_dashboard_tst',
    pathMatch: 'prefix'
  },

  */
  { path: '**', component: DashboardComponent },
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule { }
