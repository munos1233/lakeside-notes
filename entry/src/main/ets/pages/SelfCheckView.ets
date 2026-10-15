import { Theme } from '../common/Theme';
import { CardFrame } from '../components/UiParts';

@Component
export struct SelfCheckView {
  build() {
    Column() {
      CardFrame() {
        Text('体检')
          .width('100%')
          .fontSize(18)
          .fontColor(Theme.text)
      }
    }
    .width('100%')
    .height('100%')
    .padding(16)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(Theme.page)
  }
}
