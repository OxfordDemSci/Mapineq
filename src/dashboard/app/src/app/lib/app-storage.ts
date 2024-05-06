
export class AppStorage {
  localStorageId: string;
  // localStorageStr: string;

  constructor(lsId) {
    this.localStorageId = lsId;
    // console.log('storage constructed: ', lsId);
    // this.localStorageStr = JSON.stringify(lsVal);
  }

  public read(): any {
    // return 'boe';
    if (localStorage.getItem(this.localStorageId)) {
      // console.log(typeof(localStorage.getItem(this.localStorageId)));
      return localStorage.getItem(this.localStorageId);
    } else {
      return false;
    }
  }

  public write(text): boolean {
    localStorage.setItem(this.localStorageId, text);
    return true;
  }

  public readData(): any {
    // return 'boe';
    if (localStorage.getItem(this.localStorageId)) {
      // console.log(typeof(localStorage.getItem(this.localStorageId)));
      return JSON.parse(localStorage.getItem(this.localStorageId));
    } else {
      return false;
    }
  }

  public writeData(data): boolean {
    const dataJson = JSON.stringify(data);
    localStorage.setItem(this.localStorageId, dataJson);
    return true;
  }

  public initData(data): any {
    let tmpData = this.readData();
    // console.log('tmpData: ', tmpData);
    if (!tmpData) {
      this.writeData(data);
      return data;
    } else {
      return tmpData;
    }
  }

  public init(text): any {
    let tmpText = this.read();
    // console.log('tmpData: ', tmpData);
    if (!tmpText) {
      this.write(text);
      return text;
    } else {
      return tmpText;
    }
  }

  public initNumber(number): any {
    let tmpNumber = this.read();
    // console.log('tmpData: ', tmpData);
    if (!tmpNumber) {
      this.write(number);
      return number;
    } else {
      return Number(tmpNumber);
    }
  }

} // END CLASS AppStorage

/*
public readStatusFromStorage(): void {
  if (localStorage.getItem(localStoragePrefix + '_game_status')) {
  const tmpStatus = JSON.parse(localStorage.getItem(localStoragePrefix + '_game_status'));
  this.gStatus.gameCode = tmpStatus.gameCode;
  this.gStatus.gamePart = Number(tmpStatus.gamePart);
  this.gStatus.lastLat = Number(tmpStatus.lastLat);
  this.gStatus.lastLon = Number(tmpStatus.lastLon);
} else {
  this.saveStatusToStorage();
}

} // END FUNCTION readStatusFromStorage

public saveStatusToStorage(): void {
  const tmpStatus = {
    gamePart: this.gStatus.gamePart.toString(),
    lastLat: this.gStatus.lastLat.toString(),
    lastLon: this.gStatus.lastLon.toString(),
    gameCode: this.gStatus.gameCode
  };
  localStorage.setItem(localStoragePrefix + '_game_status', JSON.stringify(tmpStatus));
} // END FUNCTION saveStatusToStorage
*/
