import { Injectable } from '@angular/core';
import {HttpClient} from "@angular/common/http";
import {catchError, Observable, of, tap} from "rxjs";

@Injectable({
  providedIn: 'root'
})
export class FeatureService {

  // https://mapineqfeatures.web.rug.nl/collections/pgtileserv.nrbirths/items.json?filter=NUTS_ID=%27NL12%27&properties=year,entity&limit=100
  baseUrl: string = '';

  constructor(private httpClient: HttpClient) {
    //this.baseUrl = 'https://mapineqfeatures.web.rug.nl/collections/pgtileserv.nrbirths/items.json';
    this.baseUrl = 'https://mapineqfeatures.web.rug.nl/';
  }

  public getFeaturesByArea(areas:any, table: string): Observable<any> {
    //areas.sort(())
    let nuts_ids = areas.map((xx: any) => {
      return "'" + xx['nuts_id'] + "'";
    });
    nuts_ids.sort();
    let nutsstring  = nuts_ids.join(',');
    console.log('nutsstring',nutsstring)
    return this.httpClient.get<string>(`${this.baseUrl}collections/pgtileserv.${table}/items.json?filter=nuts_id in (${nutsstring})&limit=500`).pipe(
      tap((result) => {
        //console.log(result);
      }),
      catchError(this.handleError('search', 'ERROR')))
  }

  public getFeaturesByYear(year:number, table: string): Observable<any> {
    //areas.sort(())

    return this.httpClient.get<string>(`${this.baseUrl}functions/postgisftw.onlydata/items.json?_year=${year}&table1=${table}&limit=1500`).pipe(
      tap((result) => {
        console.log(result);
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
