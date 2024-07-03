import config from '../../assets/config.json';

export class BaseLayer {

  tileServer: string;

  constructor() {
      this.tileServer = config.tileServer;
  }

}
