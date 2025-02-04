import { Injectable } from '@angular/core';
import {HttpClient} from "@angular/common/http";
import {catchError, Observable, of, tap} from "rxjs";

import config from '../../assets/config.json';

@Injectable({
  providedIn: 'root'
})
export class FeatureService {

  baseUrl: string = '';


  constructor(private httpClient: HttpClient) {

    this.baseUrl = config.featureServer;
  }

  public getFeaturesByArea(areas:any, table: string): Observable<any> {
    //areas.sort(())
    let nuts_ids = areas.map((xx: any) => {
      return "'" + xx['nuts_id'] + "'";
    });
    nuts_ids.sort();
    let nutsstring  = nuts_ids.join(',');
    console.log('nutsstring',nutsstring)
    return this.httpClient.get<string>(`${this.baseUrl}collections/pgtileserv.${table}/items.json?filter=nuts_id in (${nutsstring})&limit=2500`).pipe(
      tap((result) => {
        //console.log(result);
      }),
      catchError(this.handleError('search', 'ERROR')))
  }

  public getFeaturesByYear(year:number, table: string): Observable<any> {
    //areas.sort(())

    return this.httpClient.get<string>(`${this.baseUrl}functions/postgisftw.onlydata/items.json?_year=${year}&table1=${table}&limit=2500`).pipe(
      tap((result) => {
        //console.log(result);
      }),
      catchError(this.handleError('search', 'ERROR')))
  }

  // IN BIVARIATE CASE: OUTCOME
  public getSourcesByYearAndNutsLevel(year: string, nutslevel: string, use_case: number): Observable<any> {
    //areas.sort(())
    let parameters = this.getParameters(`_year=${year}&_level=${nutslevel}&limit=2500`, use_case, '&_function=Outcome');
    return this.httpClient.get<string>(`${this.baseUrl}functions/postgisftw.get_source_by_year_nuts_level/items.json?${parameters}`).pipe(
      tap((result) => {
        //console.log(result);
      }),
      catchError(this.handleError('search', 'ERROR')))
  }

  public getColumnValuesBySource(resource: string, year: string, nutslevel: string): Observable<any> {
    //areas.sort(())

    return this.httpClient.get<string>(`${this.baseUrl}functions/postgisftw.get_column_values_source/items.json?_resource=${resource}&_year=${year}&_level=${nutslevel}&limit=100`).pipe(
        tap((result) => {
          //console.log(result);
        }),
        catchError(this.handleError('search', 'ERROR')))
  }

  public getColumnValuesBySourceJson(resource: string, selectionJson: string, use_case: number): Observable<any> {
    //areas.sort(())
    let parameters = this.getParameters(`_resource=${resource}&source_selections=${selectionJson}&limit=100`, use_case);
    return this.httpClient.get<string>(`${this.baseUrl}functions/postgisftw.get_column_values_source_json/items.json?${parameters}`).pipe(
        tap((result) => {
          //console.log(result);
        }),
        catchError(this.handleError('search', 'ERROR')))
  } // END FUNCTION getColumnValuesBySourceJson

  public getAllSources(): Observable<any> {
    return this.httpClient.get<string>(`${this.baseUrl}functions/postgisftw.get_all_sources/items.json?&limit=2500`).pipe(
      tap((result) => {
        //console.log(result);
      }),
      catchError(this.handleError('search', 'ERROR')))
  }

  //postgisftw.get_year_nuts_level_from_source

  public getInfoByReSource(resource: string, use_case: number): Observable<any> {
    let parameters = this.getParameters(`_resource=${resource}&limit=2500`, use_case)
    return this.httpClient.get<string>(`${this.baseUrl}functions/postgisftw.get_year_nuts_level_from_source/items.json?${parameters}`).pipe(
      tap((result) => {
        //console.log(result);
      }),
      catchError(this.handleError('search', 'ERROR')))
  }

  public getNutsLevels(use_case: number = -1): Observable<any> {
    let parameters = this.getParameters(`limit=100`, use_case)
    return this.httpClient.get<string>(`${this.baseUrl}functions/postgisftw.get_levels/items.json?${parameters}`).pipe(
        tap((result) => {
          //console.log(result);
        }),
        catchError(this.handleError('search', 'ERROR')))

  }


  //postgisftw.get_source_by_nuts_level
  // IN BIVARIATE CASE: PREDICTOR
  public getResourceByNutsLevel(nutslevel: string, use_case: number): Observable<any> {
    let parameters = this.getParameters(`_level=${nutslevel}&limit=2500`, use_case, '&_function=Predictor');
    return this.httpClient.get<string>(`${this.baseUrl}functions/postgisftw.get_source_by_nuts_level/items.json?${parameters}`).pipe(
      tap((result) => {
        //console.log(result);
      }),
      catchError(this.handleError('search', 'ERROR')))
  }

  private getParameters(base: string, use_case: number, extraUseCaseString: string = ''): string {
    let parameters = base;
    if (use_case > -1) {
      parameters += `&_use_case=${use_case}`;
      if (extraUseCaseString.trim() !== '') {
        parameters += extraUseCaseString;
      }
    }
    return parameters;

  }



  public getResourceByYear(year: number): Observable<any> {
    return this.httpClient.get<string>(`${this.baseUrl}functions/postgisftw.get_source_by_year/items.json?_year=${year}&limit=2500`).pipe(
      tap((result) => {
        //console.log(result);
      }),
      catchError(this.handleError('search', 'ERROR')))
  }

  public getUseCase(use_case: number): Observable<any> {
    return this.httpClient.get<string>(`${this.baseUrl}functions/postgisftw.get_use_cases/items.json?_use_case=${use_case}&limit=100`).pipe(
        tap((result) => {
          //console.log(result);
        }),
        catchError(this.handleError('search', 'ERROR')))
  }

  //TODO juiste jaar kiezen
  public getNutsAreas(nutslevel: number): Observable<any> {
    console.log('getNutsAreas',nutslevel);
    return this.httpClient.get<string>(`${this.baseUrl}collections/areas.nuts_2003/items.json?filter=levl_code=${nutslevel}&limit=2500`).pipe(
      tap((result) => {
        console.log(result);
      }),
      catchError(this.handleError('search', 'ERROR')))

  }


  public getTestXYData(): Observable<any> {
    return this.httpClient.get<string>(`${this.baseUrl}functions/postgisftw.xydata_withtables/items.json?_year=2014&table1=unemployment&table2=public.%22DEMO_R_MLIFEXP%22&limit=2500`).pipe(
      tap((result) => {
        //console.log(result);
      }),
      catchError(this.handleError('search', 'ERROR')))
  }

  public getRealXYData(): Observable<any> {
    return this.httpClient.get<string>(`${this.baseUrl}functions/postgisftw.get_xy_data/items.json?_level=2&_year=2018&X_JSON={%22source%22:%22TGS00010%22,%22conditions%22:[{%22field%22:%22isced11%22,%22value%22:%22TOTAL%22},{%22field%22:%22unit%22,%22value%22:%22PC%22},{%22field%22:%22age%22,%22value%22:%22Y_GE15%22},{%22field%22:%22sex%22,%22value%22:%22T%22},{%22field%22:%22freq%22,%22value%22:%22A%22}]}&Y_JSON={%22source%22:%22DEMO_R_MLIFEXP%22,%22conditions%22:[{%22field%22:%22unit%22,%22value%22:%22YR%22},{%22field%22:%22age%22,%22value%22:%22Y_LT1%22},{%22field%22:%22sex%22,%22value%22:%22T%22},{%22field%22:%22freq%22,%22value%22:%22A%22}]}&limit=2500`).pipe(
        tap((result) => {
          //console.log(result);
        }),
        catchError(this.handleError('search', 'ERROR')))
  }

  public getXYData(regionLevel: string, year: string, selectionJsonX: string, selectionJsonY: string): Observable<any> {
    return this.httpClient.get<string>(`${this.baseUrl}functions/postgisftw.get_xy_data/items.json?_level=${regionLevel}&_predictor_year=${year}&_outcome_year=${year}&X_JSON=${selectionJsonX}&Y_JSON=${selectionJsonY}&limit=2500`).pipe(
        tap((result) => {
          //console.log(result);
        }),
        catchError(this.handleError('search', 'ERROR')))
  } // END FUNCTION getXYData


  public getXData(regionLevel: string, year: string, selectionJsonX: string): Observable<any> {
    return this.httpClient.get<string>(`${this.baseUrl}functions/postgisftw.get_x_data/items.json?_level=${regionLevel}&_year=${year}&X_JSON=${selectionJsonX}&limit=2500`).pipe(
        tap((result) => {
          //console.log(result);
        }),
        catchError(this.handleError('search', 'ERROR')))
  } // END FUNCTION getXData

  public searchCatalogue(searchtext: string): Observable<any> {
    return this.httpClient.get<string>(`${this.baseUrl}functions/postgisftw.search_sources/items.json?_search_string=${searchtext}&limit=2500`).pipe(
        tap((result) => {
          //console.log(result);
        }),
        catchError(this.handleError('search', 'ERROR')))
  }


  handleError<T>(operation = 'operation', result?: T) {
    return (error: any): Observable<T> => {

      // TODO: send the error to remote logging infrastructure
      console.error(error); // log to console instead

      // TODO: better job of transforming error for user consumption
      console.log(`${operation} failed: ${error.message}`);

      // Let the app keep running by returning an empty result.
      return of(result as T);
    };
  }


}
