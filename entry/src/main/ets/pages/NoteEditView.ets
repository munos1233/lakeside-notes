import { common } from '@kit.AbilityKit';
import { Theme } from '../common/Theme';
import { CardFrame, GoldButton, InfoLine } from '../components/UiParts';
import { Note, localIso } from '../model/NoteTypes';
import { NoteStore } from '../model/NoteStore';

@Component
export struct NoteEditView {
  @Prop noteId: string = '';
  @State private busy: boolean = false;
  onDone: () => void = () => {
  };

  build() {
    Column() {
      CardFrame() {
        InfoLine({ label: '笔记', value: this.noteId })
      }
      GoldButton({
        label: '保存',
        canTap: !this.busy && this.noteId.length > 0,
        onTap: (): void => {
          this.saveNote();
        }
      })
      .margin({ bottom: 12 })
      GoldButton({
        label: '删除',
        canTap: !this.busy && this.noteId.length > 0,
        onTap: (): void => {
          this.deleteNote();
        }
      })
    }
    .width('100%')
    .height('100%')
    .padding(16)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(Theme.page)
  }

  private saveNote(): void {
    if (this.busy || this.noteId.length === 0) {
      return;
    }
    let ctx = this.hostContext();
    if (ctx === undefined) {
      return;
    }
    this.busy = true;
    this.saveWith(ctx, this.noteId);
  }

  private saveWith(ctx: common.UIAbilityContext, targetId: string): void {
    NoteStore.load(ctx).then((notes: Note[]) => {
      let next: Note[] = [];
      let found = false;
      for (let i = 0; i < notes.length; i++) {
        let item = notes[i];
        if (item.id !== targetId) {
          next.push(item);
          continue;
        }
        let updated = new Note();
        updated.id = item.id;
        updated.title = item.title;
        updated.body = item.body;
        updated.pinned = item.pinned;
        updated.createdAt = item.createdAt;
        updated.updatedAt = localIso(new Date());
        next.push(updated);
        found = true;
      }
      if (!found) {
        this.busy = false;
        return Promise.resolve(false);
      }
      return NoteStore.save(ctx, next);
    }).then((saved: boolean) => {
      this.busy = false;
      if (saved) {
        this.onDone();
      }
    }).catch(() => {
      this.busy = false;
    });
  }

  private deleteNote(): void {
    if (this.busy || this.noteId.length === 0) {
      return;
    }
    let ctx = this.hostContext();
    if (ctx === undefined) {
      return;
    }
    this.busy = true;
    this.deleteWith(ctx, this.noteId);
  }

  private deleteWith(ctx: common.UIAbilityContext, targetId: string): void {
    NoteStore.load(ctx).then((notes: Note[]) => {
      let next: Note[] = [];
      let found = false;
      for (let i = 0; i < notes.length; i++) {
        if (notes[i].id === targetId) {
          found = true;
          continue;
        }
        next.push(notes[i]);
      }
      if (!found) {
        this.busy = false;
        return Promise.resolve(false);
      }
      return NoteStore.save(ctx, next);
    }).then((saved: boolean) => {
      this.busy = false;
      if (saved) {
        this.onDone();
      }
    }).catch(() => {
      this.busy = false;
    });
  }

  private hostContext(): common.UIAbilityContext | undefined {
    let host = this.getUIContext().getHostContext();
    if (host === undefined) {
      return undefined;
    }
    return host as common.UIAbilityContext;
  }
}
