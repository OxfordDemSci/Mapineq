import { Component } from '@angular/core';
import {MapComponent} from "../map/map.component";
import {UsercontrolsComponent} from "../usercontrols/usercontrols.component";

@Component({
  selector: 'app-home',
  standalone: true,
  imports: [MapComponent, UsercontrolsComponent],
  templateUrl: './home.component.html',
  styleUrl: './home.component.css'
})
export class HomeComponent {

}
