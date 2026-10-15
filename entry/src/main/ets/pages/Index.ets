import { Theme } from '../common/Theme';
import { NoteEditView } from './NoteEditView';
import { NoteListView } from './NoteListView';
import { SelfCheckView } from './SelfCheckView';

@Entry
@Component
struct Index {
  @State private tab: number = 0;
  @State private noteId: string = '';
  @State private pageShowSeq: number = 0;
  private tabs: string[] = ['列表', '编辑', '体检'];

  onPageShow(): void {
    this.pageShowSeq++;
  }

  build() {
    Column() {
      Column() {
        if (this.tab === 0) {
          NoteListView({
            pageShowSeq: this.pageShowSeq,
            onOpen: (id: string): void => {
              this.openNote(id);
            },
            onCreate: (): void => {
              this.openNote('');
            }
          })
        } else if (this.tab === 1) {
          NoteEditView({
            noteId: this.noteId,
            onDone: (): void => {
              this.finishEdit();
            }
          })
        } else {
          SelfCheckView()
        }
      }
      .layoutWeight(1)
      .width('100%')

      Row() {
        ForEach(this.tabs, (name: string, index: number) => {
          Text(name)
            .fontSize(15)
            .fontWeight(this.tab === index ? FontWeight.Medium : FontWeight.Regular)
            .fontColor(this.tab === index ? Theme.ink : Theme.text)
            .textAlign(TextAlign.Center)
            .layoutWeight(1)
            .height(Theme.hitHeight)
            .borderRadius(10)
            .backgroundColor(this.tab === index ? Theme.gold : Theme.cardAlt)
            .onClick(() => {
              if (index === 0) {
                this.finishEdit();
                return;
              }
              this.tab = index;
            })
        }, (name: string) => name)
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 12 })
      .backgroundColor(Theme.navy)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.page)
  }

  private openNote(id: string): void {
    this.noteId = id;
    this.tab = 1;
  }

  private finishEdit(): void {
    this.noteId = '';
    this.tab = 0;
  }
}
