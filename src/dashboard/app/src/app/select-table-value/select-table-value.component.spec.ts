import { ComponentFixture, TestBed } from '@angular/core/testing';

import { SelectTableValueComponent } from './select-table-value.component';

describe('SelectTableValueComponent', () => {
  let component: SelectTableValueComponent;
  let fixture: ComponentFixture<SelectTableValueComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [SelectTableValueComponent]
    })
    .compileComponents();
    
    fixture = TestBed.createComponent(SelectTableValueComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
