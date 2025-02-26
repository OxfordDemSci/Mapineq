import {Component, ElementRef, inject, OnInit, ViewChild} from '@angular/core';

import {FormControl} from "@angular/forms";
import {FeatureService} from "../services/feature.service";
import {debounceTime, distinctUntilChanged, filter, finalize, Observable, switchMap, tap} from "rxjs";
import {map, startWith} from 'rxjs/operators';
import {MatAutocompleteSelectedEvent} from "@angular/material/autocomplete";
import {MatChipInputEvent, MatChipsModule} from "@angular/material/chips";
import {LiveAnnouncer} from "@angular/cdk/a11y";
import {COMMA, ENTER} from "@angular/cdk/keycodes";
import {MatIconModule} from '@angular/material/icon';
import {AsyncPipe} from '@angular/common';


// import {AppVersionAndBuildChecker} from "../lib/app-version-and-build-checker";

@Component({
  selector: 'app-datacatalogue',
  templateUrl: './datacatalogue.component.html',
  styleUrl: './datacatalogue.component.css'
})
export class DatacatalogueComponent implements OnInit {

  // versionChecker: AppVersionAndBuildChecker;

  isLoading = false;
  errorMsg!: string;
  searchResult: any;
  filteredSearchResults: any;
  placeHolder: string = 'Words in title or description';
  searchResultsCtrl = new FormControl();
  minLengthTerm = 2;
  searchText: string = 'xxxxxx';


  randomTags: any;
  allFruits: any;
  // filteredOptions: Observable<string[]>;





  separatorKeysCodes: number[] = [ENTER, COMMA];
  fruitCtrl = new FormControl('');
  filteredFruits: Observable<string[]>;
  fruits: string[] = ['health'];
  // allFruits: string[] = ['Apple', 'Lemon', 'Lime', 'Orange', 'Strawberry'];

  @ViewChild('fruitInput') fruitInput: ElementRef<HTMLInputElement>;

  announcer = inject(LiveAnnouncer);

  constructor(private featureService: FeatureService) {
    // this.filteredSearchResults = [];
    this.initData();

    this.randomTags = ['death', 'work', 'traffic', 'government', 'demography', 'nature', 'historic', 'yearly'];

    this.allFruits = this.randomTags.slice().sort();


    this.filteredFruits = this.fruitCtrl.valueChanges.pipe(
      startWith(null),
      map((fruit: string | null) => (fruit ? this._filter(fruit) : this.allFruits.slice())),
    );

  }

  add(event: MatChipInputEvent): void {
    const value = (event.value || '').trim();

    // Add our fruit
    if (value) {
      this.fruits.push(value);
    }

    // Clear the input value
    event.chipInput!.clear();

    this.fruitCtrl.setValue(null);
  }

  remove(fruit: string): void {
    const index = this.fruits.indexOf(fruit);

    if (index >= 0) {
      this.fruits.splice(index, 1);

      this.announcer.announce(`Removed ${fruit}`);
    }
  }

  selected(event: MatAutocompleteSelectedEvent): void {
    this.fruits.push(event.option.viewValue);
    this.fruitInput.nativeElement.value = '';
    this.fruitCtrl.setValue(null);
  }

  private _filter(value: string): string[] {
    const filterValue = value.toLowerCase();

    return this.allFruits.filter(fruit => fruit.toLowerCase().includes(filterValue));
  }


  //https://stackoverflow.com/questions/70875775/angular-autocomplete-loading-from-api-reactivity

  ngOnInit() {

    // this.versionChecker = new AppVersionAndBuildChecker();

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

  addMetaDataUrl() {
    this.filteredSearchResults.map((item:any) => {
      item.metadataurl = 'https://doi.org/10.2908/' + item.f_resource;
      return item;
    })
  }


  protected readonly Math = Math;
  protected readonly JSON = JSON;
  protected readonly String = String;

  render(f_years: any) {
    return JSON.parse(f_years).map(Number);
  }

  getMaxRegionLevel(jsonArray: any) {
    // console.log('getMAxRegionLevel()', jsonArray);
    // let actualLevelsArray = JSON.parse(jsonArray);
    let actualLevelsArray = jsonArray;

    if (actualLevelsArray === null  ||  actualLevelsArray.length === 0) {
      return '';
    } else {
      actualLevelsArray.sort().reverse();
      return actualLevelsArray[0].toString();
    }

  } // getMaxRegionLevel


  jsonArrayToString(jsonArray: any, joinString: string) {
    // console.log('jsonArrayToString()', jsonArray, joinString);
    // let actualArray = JSON.parse(jsonArray);
    let actualArray = jsonArray;

    if (actualArray === null) {
      return '-none-';
    } else {
      actualArray.sort();
      return actualArray.join(joinString);
    }

  } // END FUNCTION jsonArrayToString


  getOneOrToRandomTags() {
    // console.log();

    this.shuffle(this.randomTags);

    let tmpTags = ['health'];
    let nmbrTags = Math.round(1 + Math.random());
    for (let i = 0; i < nmbrTags; i++) {
      tmpTags.push(this.randomTags[i]);
    }
    return tmpTags;
  }

  shuffle(array) {
    let currentIndex = array.length;

    // While there remain elements to shuffle...
    while (currentIndex != 0) {

      // Pick a remaining element...
      let randomIndex = Math.floor(Math.random() * currentIndex);
      currentIndex--;

      // And swap it with the current element.
      [array[currentIndex], array[randomIndex]] = [
        array[randomIndex], array[currentIndex]];
    }
  }


}
