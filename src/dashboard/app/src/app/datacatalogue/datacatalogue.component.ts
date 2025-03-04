import {AfterViewInit, Component, ElementRef, inject, OnInit, ViewChild} from '@angular/core';
import {FormControl} from "@angular/forms";
import {FeatureService} from "../services/feature.service";
import {debounceTime, distinctUntilChanged, filter, finalize, Observable, switchMap, tap, map, startWith} from "rxjs";
import {COMMA, ENTER} from "@angular/cdk/keycodes";
import {MatChipInputEvent} from "@angular/material/chips";
import {LiveAnnouncer} from "@angular/cdk/a11y";
import {MatAutocompleteSelectedEvent} from "@angular/material/autocomplete";

// import {AppVersionAndBuildChecker} from "../lib/app-version-and-build-checker";

@Component({
  selector: 'app-datacatalogue',
  templateUrl: './datacatalogue.component.html',
  styleUrl: './datacatalogue.component.css'
})
export class DatacatalogueComponent implements OnInit, AfterViewInit {

  // versionChecker: AppVersionAndBuildChecker;

  isLoading = false;
  errorMsg!: string;
  searchResult: any;
  filteredSearchResults: any;
  placeHolder: string = 'Search title and description';
  searchResultsCtrl = new FormControl();
  minLengthTerm = 2;
  searchText: string = 'xxxxxx';


  tagsAll: any;
  tagsSelectable: any;
  tagsSeparatorKeyCodes: number[] = [ENTER, COMMA];
  tagsFormControl = new FormControl('');
  tagsFiltered: Observable<string[]>;
  tagsSelected: any;

  @ViewChild('tagsInput') tagsInput: ElementRef<HTMLInputElement>;

  tagsAnnouncer = inject(LiveAnnouncer);

  constructor(private featureService: FeatureService) {
    // this.filteredSearchResults = [];

    this.tagsSelected = [];
    this.tagsSelectable = [];

    this.getAllTags();

    this.initData();
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

    // this.initTagsAutocomplete();

  } // END FUNCTION ngOnInit

  initTagsAutocomplete() {
    this.tagsFiltered = this.tagsFormControl.valueChanges.pipe(
      startWith(''),
      map((fruit: string | null) => (fruit ? this._tagsFilter(fruit) : this.tagsSelectable.slice())),
    );
  } // END FUNCTION initTagsAutocomplete


  ngAfterViewInit(): void {


  } // END FUNCTION ngAfterViewInit


  /* tags function  START */

  getAllTags(): void {
    this.tagsAll = [];
    this.featureService.getCatalogueTags().subscribe( (data) => {
      console.log('getCatalogueTags() ...', data);
      data.forEach( dataItem => {
        this.tagsAll.push(dataItem.f_description);
      });
      this.tagsAll.sort();
      this.tagsSelectable = this.tagsAll.slice();

      this.initTagsAutocomplete();

    })
  } // END FUNCTION getAllTags





  tagsFormAddChipEvent(event: MatChipInputEvent): void {
    const value = (event.value || '').trim();

    this.tagsAdd(value);
    /*
    // Add our fruit (only if selectable option)
    if (value  &&  this.tagsSelectable.includes(value)) {
      this.tagsSelected.push(value);

      const index = this.tagsSelectable.indexOf(value);
      this.tagsSelectable.splice(index, 1);

      // Clear the input value
      event.chipInput!.clear();

      this.tagsFormControl.setValue(null);

    }
    */

  } // END FUNCTION tagsFormAddChipEvent

  tagsAdd(tag: string): void {
    console.log('tagsAdd() ...', tag, this.tagsSelectable.includes(tag), this.tagsSelectable);

    // Add our fruit (only if selectable option)
    if (tag  &&  this.tagsSelectable.includes(tag)) {
      this.tagsSelected.push(tag);

      const index = this.tagsSelectable.indexOf(tag);
      this.tagsSelectable.splice(index, 1);

      // Clear the input value
      // event.chipInput!.clear();
      this.tagsInput.nativeElement.value = '';

      this.tagsFormControl.setValue(null);

    }
  } // END FUNCTION tagsAdd


  tagsRemove(tag: string): void {
    const index = this.tagsSelected.indexOf(tag);

    if (index >= 0) {
      this.tagsSelected.splice(index, 1);

      this.tagsAnnouncer.announce(`Removed ${tag}`);

      // add to allFruits again
      this.tagsSelectable.push(tag);
      this.tagsSelectable.sort();

      // this.tagsInput.nativeElement.value = '';
      // this.tagsFormControl.setValue(null);
      // reload suggestions
      this.tagsFormControl.setValue(this.tagsInput.nativeElement.value);

    }
  } // END FUNCTION tagsRemove

  // tagsFormAddChipEvent
  tagsFormAutocompleteSelectedEvent(event: MatAutocompleteSelectedEvent): void {
    const value = (event.option.viewValue || '').trim();

    this.tagsAdd(value);

    /*
    if (this.tagsSelectable.includes(event.option.viewValue)) {
      this.tagsSelected.push(event.option.viewValue);
      const index = this.tagsSelectable.indexOf(event.option.viewValue);
      this.tagsSelectable.splice(index, 1);
      this.tagsInput.nativeElement.value = '';
      this.tagsFormControl.setValue(null);
    }
    */
  } // END FUNCTION tagsFormAutocompleteSelectedEvent

  private _tagsFilter(value: string): string[] {
    const filterValue = value.toLowerCase();

    return this.tagsSelectable.filter(tag => tag.toLowerCase().includes(filterValue));
  } // END FUNCTION _tagsFilter

  /* tags function  END */





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


}
