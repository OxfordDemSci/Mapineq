import {Component, OnInit} from '@angular/core';
import {FormControl} from "@angular/forms";
import {FeatureService} from "../services/feature.service";
import {debounceTime, distinctUntilChanged, filter, finalize, switchMap, tap} from "rxjs";

@Component({
  selector: 'app-datacatalogue',
  templateUrl: './datacatalogue.component.html',
  styleUrl: './datacatalogue.component.css'
})
export class DatacatalogueComponent implements OnInit {

  isLoading = false;
  errorMsg!: string;
  searchResult: any;
  filteredSearchResults: any;
  placeHolder: string = 'Search';
  searchResultsCtrl = new FormControl();
  minLengthTerm = 2;
  searchText: string = 'xxxxxx';

  constructor(private featureService: FeatureService) {

  }


  //https://stackoverflow.com/questions/70875775/angular-autocomplete-loading-from-api-reactivity

  ngOnInit() {
    this.searchResultsCtrl.valueChanges
        .pipe(
            filter(res => {
              return res !== null && res.length >= this.minLengthTerm
            }),
            distinctUntilChanged(),
            debounceTime(700),
            tap(() => {
              this.errorMsg = "";
              this.filteredSearchResults = [];
              this.isLoading = true;
            }),
            switchMap(value => this.featureService.searchCatalogue(value)
                .pipe(
                    finalize(() => {
                      this.isLoading = false
                    }),
                )
            )
        )
        .subscribe((data: any) => {
          //console.log('data', data);
          if (data == 'ERROR') {
            //this.errorMsg = data['Error'];
            this.filteredSearchResults= [];
          } else {
            this.errorMsg = "";
            this.filteredSearchResults = data;

          }
          //console.log(this.filteredLocations);
        });
  }

  clearSelection() {
    this.searchResultsCtrl.setValue('');
    this.filteredSearchResults = [];
    // this.selectedLocationName = '';

  }

  displayWith(value: any) {
    /*
    console.log('displayWith()', value);
    return value?.name;//  + ' ' + (value?.floor);
    */
    //console.log('=== === displayWith(), fromOrTo:', this.fromOrTo);
    if (typeof value !== 'undefined'  &&  value !== null) {
      //console.log('    === displayWith()', value, value.floor);
      // return value?.name + (typeof value.floor !== 'undefined' ? ' (' + value.floor.toString() + ')' : '');//  + ' ' + (value?.floor);
      return value?.f_description;
    } else {
      //console.log('    === displayWith() --- NULL or UNDEFINED');
      return '';
    }
  }


  onSelected(event: any, formField: any, input: any) {
    //console.log(event);
    this.searchResult = event;
    // this.selectedLocationName = this.selectedLocation.name;


    // https://stackoverflow.com/questions/50771298/remove-focus-blur-on-select-programmatically-angular6-material
    setTimeout( () => {
      console.log('blur ...');
      formField._elementRef.nativeElement.classList.remove('mat-focused');
      input.blur();
    }, 250);
  }

  protected readonly Math = Math;
  protected readonly JSON = JSON;
  protected readonly String = String;

  render(f_years: any) {


    return JSON.parse(f_years).map(String);
  }
}
