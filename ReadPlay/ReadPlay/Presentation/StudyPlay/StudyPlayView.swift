//
//  StudyPlayView.swift
//  ReadPlay
//
//  Created by yun on 11/4/23.
//

import SwiftUI

struct StudyPlayView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.managedObjectContext) var managedObjectContext
  @StateObject var dataController = DataController.shared
  @StateObject var studyPlayVM: StudyPlayViewModel
  
  let screenHeight = UIScreen.main.bounds.size.height
  let fetchedVocabs: Array<Vocab>
  let studyOpt: Int
  var displayedVocabs: Array<String> = []
  var displayedImgs: Array<String> = []
  let selectedStatus: VocabStatus
  
  init(fetchedVocabs: [Vocab], selectedStatus: VocabStatus, studyOpt: Int) {
    self.fetchedVocabs = fetchedVocabs
    self.selectedStatus = selectedStatus
    self.studyOpt = studyOpt
    
    if fetchedVocabs.isEmpty {
      displayedVocabs.append("X 학습 단어 X")
      displayedImgs = ["", ]
    } else {
      // 영어만
      if studyOpt == 1 {
        displayedVocabs = fetchedVocabs.map {$0.word}
        displayedImgs = fetchedVocabs.map { "\($0.category.categoryId)_\($0.word)_img" }
      } else if studyOpt == 2 { // 한국어만
        displayedVocabs = fetchedVocabs.map {$0.meaning}
        displayedImgs = fetchedVocabs.map { "\($0.category.categoryId)_\($0.word)_img" }
      } else { // 둘다
        for vocab in fetchedVocabs {
          displayedVocabs.append(vocab.word)
          displayedVocabs.append(vocab.meaning)
          displayedImgs.append("\(vocab.category.categoryId)_\(vocab.word)_img")
          displayedImgs.append("\(vocab.category.categoryId)_\(vocab.word)_img")
        }
      }
    }
    let vocabs = self.displayedVocabs
    _studyPlayVM = StateObject(wrappedValue: StudyPlayViewModel(vocabs: vocabs))
  }
  
  var body: some View {
    VStack(alignment: .center) {
      
      backButton
      
      VStack {
        
        if (!studyPlayVM.status) {
          Text("[\(self.selectedStatus.buttonLabel)] 단계의 \n[\(StudyOpt(rawValue: studyOpt)!.studyOptWord)] 단어를 학습합니다.")
            .multilineTextAlignment(.center)
            .customFont(.headline3)
            .foregroundStyle(.blueButton)
            .padding(.top, 30)
          
          Spacer()
          
          Text("\(studyPlayVM.counter)")
            .customFont(.learningText)
            .foregroundStyle(.blueButton)
          
          Spacer()
          
          
        } else {
          
          vocabIdx
          
          if let image = UIImage(named: displayedImgs[studyPlayVM.wordIdx]) {
            Image(uiImage: image)
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(maxWidth: .infinity)
              .padding(.horizontal, 15)
              .padding(.top, 20)
              .padding(.bottom, 40)
          } else {
            Spacer()
          }
          
          Text(displayedVocabs[studyPlayVM.wordIdx])
            .customFont(.learningText)
            .foregroundStyle(.textBlack)
          
          Spacer()
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(
        RoundedRectangle(cornerRadius: 20)
          .fill(.shadow(.drop(radius: 4)))
          .foregroundColor(.surface)
      )
      .padding(.horizontal, 32)
      .padding(.vertical, 54)
      
      
      Spacer()
      
      HStack(alignment: .center) {
        
        Circle()
          .stroke(.clear, lineWidth: 18)
          .frame(width: 40, height: 40)
          .foregroundColor(.clear)
        
        Spacer()
        
        Button(action: { studyPlayVM.stopTimer() }, label: {
          HStack(spacing: 8) {
            Rectangle()
              .frame(width: 12, height: 38)
            Rectangle()
              .frame(width: 12, height: 38)
          }
          .foregroundStyle(.surface)
        })
        .frame(width: 50, height: 50)
        
        Spacer()
        
        Circle()
          .stroke(.surface, lineWidth: 18)
          .frame(width: 40, height: 40)
          .gesture(
            DragGesture(minimumDistance: 0)
              .onChanged{ _ in
                studyPlayVM.isButtonHeld()
                studyPlayVM.startTimer()
                studyPlayVM.startIncreasingTimer()
              }
              .onEnded { _ in
                studyPlayVM.isButtonReleased()
              }
          )
        
      }
      .disabled(fetchedVocabs.isEmpty)
      .padding(.horizontal, 37)
      .padding(.bottom, 50)
    }
    .alert("학습을 완료하였어요.", isPresented: $studyPlayVM.isDone) {
      Button("취소", role: .cancel, action: {
        dataController.updateStudyDate(category: fetchedVocabs[0].category, context: managedObjectContext)
      })
      
      Button("완료", action: {
        dataController.updateStudyDate(category: fetchedVocabs[0].category, context: managedObjectContext)
        dismiss()
      })
      
    } message: {
      Text("축하합니다!")
    }
    .onDisappear {
      studyPlayVM.stopTimer()
    }
    .background(backGradient())
    .navigationBarBackButtonHidden()
    
    
  }
}
extension StudyPlayView {
  
  private var vocabIdx: some View {
    Text(fetchedVocabs.isEmpty ? "0 / 0" : "\(studyPlayVM.wordIdx+1) / \(displayedVocabs.count)")
      .customFont(.body1)
      .foregroundStyle(.gray300)
      .padding(.top, 20)
  }
  private var backButton: some View {
    HStack {
      Button(action: { dismiss() }, label: {
        Image(systemName: "chevron.backward")
          .font(.system(size: 20))
          .foregroundStyle(.textWhite)
      })
      
      Spacer()
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 16)
  }
}
