import {Component, OnInit} from '@angular/core';
import {FormControl} from "@angular/forms";
import {FeatureService} from "../services/feature.service";
import {debounceTime, distinctUntilChanged, filter, finalize, switchMap, tap} from "rxjs";
import {AppVersionAndBuildChecker} from "../lib/app-version-and-build-checker";

@Component({
  selector: 'app-datacatalogue',
  templateUrl: './datacatalogue.component.html',
  styleUrl: './datacatalogue.component.css'
})
export class DatacatalogueComponent implements OnInit {

  versionChecker: AppVersionAndBuildChecker;

  isLoading = false;
  errorMsg!: string;
  searchResult: any;
  filteredSearchResults: any;
  placeHolder: string = 'Search';
  searchResultsCtrl = new FormControl();
  minLengthTerm = 2;
  searchText: string = 'xxxxxx';

  constructor(private featureService: FeatureService) {
    // this.filteredSearchResults = [];
    this.initData();
  }


  //https://stackoverflow.com/questions/70875775/angular-autocomplete-loading-from-api-reactivity

  ngOnInit() {

    this.versionChecker = new AppVersionAndBuildChecker();

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
    this.initData();
    // this.selectedLocationName = '';
  }

  initData(): void {
    this.filteredSearchResults = [];
    this.featureService.searchCatalogue('').subscribe((data) => {
      this.filteredSearchResults = data;
    })
  }

  protected readonly Math = Math;
  protected readonly JSON = JSON;
  protected readonly String = String;

  render(f_years: any) {
    return JSON.parse(f_years).map(Number);
  }

  getMaxRegionLevel(jsonArray: any) {
    let actualLevelsArray = JSON.parse(jsonArray);

    if (actualLevelsArray === null  ||  actualLevelsArray.length === 0) {
      return '';
    } else {
      actualLevelsArray.sort().reverse();
      return actualLevelsArray[0].toString();
    }

  } // getMaxRegionLevel


  jsonArrayToString(jsonArray: string, joinString: string) {
    let actualArray = JSON.parse(jsonArray);

    if (actualArray === null) {
      return '-none-';
    } else {
      actualArray.sort();
      return actualArray.join(joinString);
    }

  } // END FUNCTION jsonArrayToString


}
