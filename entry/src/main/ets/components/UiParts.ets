import { hilog } from '@kit.PerformanceAnalysisKit';
import { Theme } from '../common/Theme';

const DOMAIN: number = 0x4C4E;

@Component
export struct GoldButton {
  @Prop label: string = '';
  @Prop canTap: boolean = true;
  onTap: () => void = () => {
    hilog.info(DOMAIN, 'button', 'tap');
  };

  build() {
    Button(this.label)
      .type(ButtonType.Normal)
      .enabled(this.canTap)
      .width('100%')
      .height(46)
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .fontColor(Theme.ink)
      .backgroundColor(this.canTap ? Theme.gold : Theme.cardAlt)
      .borderRadius(12)
      .onClick(() => {
        this.onTap();
      })
  }
}

@Component
export struct InfoLine {
  @Prop label: string = '';
  @Prop value: string = '';

  build() {
    Column() {
      Text(this.label)
        .width('100%')
        .fontSize(12)
        .fontColor(Theme.muted)
      Text(this.value.length === 0 ? '—' : this.value)
        .width('100%')
        .fontSize(16)
        .fontColor(Theme.text)
        .margin({ top: 2 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 10 })
  }
}

@Component
export struct CardFrame {
  @BuilderParam content: () => void = this.placeholder;

  @Builder
  placeholder() {
  }

  build() {
    Column() {
      this.content()
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(14)
    .borderRadius(14)
    .backgroundColor(Theme.card)
    .border({ width: 1, color: Theme.line })
    .margin({ bottom: 10 })
  }
}
