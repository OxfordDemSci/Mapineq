import {Component, Inject, OnInit} from "@angular/core";
import {MAT_DIALOG_DATA, MatDialogRef} from '@angular/material/dialog';

@Component({
  selector: 'dialog-app-version-and-build-info',
  standalone: false,
  templateUrl: 'dialog-app-version-and-build-info.component.html',
  styleUrls: ['dialog-app-version-and-build-info.component.css']
})
export class DialogAppVersionAndBuildInfo implements OnInit {

  constructor(public dialogRef: MatDialogRef<DialogAppVersionAndBuildInfo>, @Inject(MAT_DIALOG_DATA) public data: any) {
  } // END CONSTRUCTOR

  ngOnInit() {
    // console.log('ngOnInit() CALLED ...', this.data);

  } // END FUNCTION ngOnInit

  onCloseClick(): void {
    console.log('onCloseClick()');
    this.dialogRef.close();
  } // END FUNCTION onCloseClick

  onCancelClick(): void {
    console.log('onCancelClick()');
    this.dialogRef.close();
  } // END FUNCTION onCancelClick

  onOkClick(data): void {
    console.log('onOkClick(), data: ', data);
    this.dialogRef.close(data);
  } // END FUNCTION onOkClick

} // END CLASS DialogAppVersionAndBuildInfo
