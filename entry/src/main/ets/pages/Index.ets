import pluralize from 'pluralize';

@Entry
@Component
struct Index {
  @State count: number = 2;
  @State name: string = "Peach";
  dialogController: CustomDialogController | null = new CustomDialogController({
    builder: CustomTextInputDialog({
      cancel: () => {
      },
      confirm: (val: string) => {
        console.log("Comfirm")
        this.name = val;
      },
      inputValue: this.name,
    })
  })

  build() {
    Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.SpaceAround, alignItems: ItemAlign.Center }) {
      Text(pluralize(this.name, this.count, true))
        .id('Message')
        .fontSize(48)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)

      Button() {
        Text('Edit item name')
          .padding(16)
          .fontColor(Color.White)
      }
      .onClick(() => {
        if (this.dialogController !== null) {
          this.dialogController.open();
        }
      })

      Flex({ justifyContent: FlexAlign.SpaceEvenly }) {
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          Text('-').fontColor(Color.White).fontSize(24)
        }
        .width(55)
        .height(55)
        .backgroundColor(0xF55A42)
        .onClick(() => this.count -= 1)
        .enabled(this.count > 1)

        Button({ type: ButtonType.Circle, stateEffect: true }) {
          Text('+').fontColor(Color.White).fontSize(24)
        }
        .width(55)
        .height(55)
        .backgroundColor(0x317aff)
        .onClick(() => {
          this.count += 1
        })
      }
    }
    .height('100%')
    .width('100%')
  }
}

@CustomDialog
@Component
struct CustomTextInputDialog {
  @State inputValue: string = "";
  controller?: CustomDialogController
  cancel: () => void = () => {
  }
  confirm: (result: string) => void = () => {
  }

  build() {
    Column() {
      Text('Edit item name').fontSize(20).margin({ top: 10, bottom: 10 })
      TextInput({ placeholder: '', text: this.inputValue }).height(60).width('90%')
        .onChange((value: string) => {
          this.inputValue = value;
        })
      // Text('').fontSize(16).margin({ bottom: 10 })
      Flex({ justifyContent: FlexAlign.SpaceAround }) {
        Button('cancel')
          .onClick(() => {
            if (this.controller != undefined) {
              this.controller.close()
              this.cancel()
            }
          }).backgroundColor(0xffffff).fontColor(Color.Black)
        Button('confirm')
          .onClick(() => {
            if (this.controller != undefined) {
              this.controller.close()
              this.confirm(this.inputValue);
            }
          }).backgroundColor(0xffffff).fontColor(Color.Red)
      }.margin({ bottom: 10 })
    }.borderRadius(10)
  }
}