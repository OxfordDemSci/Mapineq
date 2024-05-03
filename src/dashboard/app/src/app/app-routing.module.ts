import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { DashboardComponent } from './dashboard/dashboard.component';
import {UsercontrolsComponent} from "./usercontrols/usercontrols.component";

const routes: Routes = [
  { path: '', component: DashboardComponent },
  // { path: 'map', component: MapComponent }
  { path: 'usercontrols', component: UsercontrolsComponent },
  { path: '**', component: DashboardComponent },

];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule { }
