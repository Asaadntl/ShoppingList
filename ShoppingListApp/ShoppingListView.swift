//
//  ShoppingListView.swift
//  ShoppingListApp
//
//  Created by Asaad Alhadeethi on 2023-11-24.
//

import SwiftUI

struct Item: Identifiable, Hashable {
    var id = UUID()
    var name: String
    var isCompleted: Bool
    var image: UIImage? = nil
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct ShoppingListView: View {
    @State private var newItem: String = ""
    @State private var unpurchasedItems: [Item] = [Item(name: "Bröd", isCompleted: false)]
    @State private var purchasedItems: [Item] = []
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingEditScreen = false
    @State private var selectedItem: Item?
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var showingClearConfirmation = false

    var body: some View {
        VStack {
            HStack {
                TextField("Lägg till ny artikel", text: $newItem)
                    .padding()
                Button("Lägg till") {
                    addItem()
                }
                .padding()
                
                Button("Lägg till bild") {
                    showingImagePicker = true
                }
                .padding()
            }
            
            Text("Att Köpa")
                .font(.headline)
            List {
                ForEach(unpurchasedItems.indices, id: \.self) { index in
                    if let image = unpurchasedItems[index].image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                            .cornerRadius(8)
                    } else {
                        itemRow(for: $unpurchasedItems[index])
                    }
                }
                .onDelete(perform: deleteItem)
            }
            
            Text("Köpta")
                .font(.headline)
            List {
                ForEach(purchasedItems.indices, id: \.self) { index in
                    itemRow(for: $purchasedItems[index])
                }
                .onDelete(perform: deletePurchasedItem)
            }

            Button("Rensa köpta artiklar") {
                showingClearConfirmation = true
            }
            .padding()
            .foregroundColor(.red)
            .alert(isPresented: $showingClearConfirmation) {
                Alert(
                    title: Text("Bekräfta rensning"),
                    message: Text("Är du säker på att du vill rensa alla köpta artiklar?"),
                    primaryButton: .destructive(Text("Rensa")) {
                        purchasedItems.removeAll()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $inputImage)
        }
        .onChange(of: inputImage) { _ in loadImage() }
        .sheet(isPresented: $showingEditScreen) {
            // Use optional binding to unwrap selectedItem safely
            if let selectedItem = selectedItem {
                // Create a binding to selectedItem using the unwrapped value
                ItemEditView(item: Binding<Item>(
                    get: { selectedItem },
                    set: { newItem in
                        // Update the selectedItem in your state
                        self.selectedItem = newItem
                        // If you want to immediately update the item in your list, you can call updateItem here
                        self.updateItem(newItem)
                    }
                )) {
                    // This closure is called when an item is saved in ItemEditView
                    updatedItem in
                    // Update the item in your list
                    self.updateItem(updatedItem)
                    // Reset selectedItem to nil to dismiss the sheet
                    self.selectedItem = nil
                }
            }
        }
    }

    func addItem() {
        let trimmedItem = newItem.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedItem.isEmpty {
            if !unpurchasedItems.contains(where: { $0.name.lowercased() == trimmedItem.lowercased() }) {
                let newItemToAdd = Item(name: trimmedItem, isCompleted: false)
                unpurchasedItems.insert(newItemToAdd, at: 0)
                newItem = ""
            } else {
                alertMessage = "\(trimmedItem) finns redan i listan."
                showingAlert = true
            }
        }
    }

    func itemRow(for itemBinding: Binding<Item>) -> some View {
        HStack {
            Text(itemBinding.wrappedValue.name)
            Spacer()
            if itemBinding.wrappedValue.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
            
            Button(action: {
                selectedItem = itemBinding.wrappedValue
                showingEditScreen = true
            }) {
                Image(systemName: "pencil")
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .contentShape(Rectangle())
        .onTapGesture {
            moveItem(itemBinding.wrappedValue)
        }
    }

    func loadImage() {
        guard let inputImage = self.inputImage else { return }
        let newItemWithImage = Item(name: "Ny Bild", isCompleted: false, image: inputImage)
        unpurchasedItems.insert(newItemWithImage, at: 0)
        self.inputImage = nil // Reset the state
    }

    func moveItem(_ item: Item) {
        if let index = unpurchasedItems.firstIndex(where: { $0.id == item.id }) {
            unpurchasedItems.remove(at: index)
            purchasedItems.append(Item(name: item.name, isCompleted: true, image: item.image))
        } else if let index = purchasedItems.firstIndex(where: { $0.id == item.id }) {
            purchasedItems.remove(at: index)
            unpurchasedItems.insert(Item(name: item.name, isCompleted: false, image: item.image), at: 0)
        }
    }

    func updateItem(_ newItem: Item) {
        if let index = unpurchasedItems.firstIndex(where: { $0.id == newItem.id }) {
            unpurchasedItems[index] = newItem
        } else if let index = purchasedItems.firstIndex(where: { $0.id == newItem.id }) {
            purchasedItems[index] = newItem
        }
    }

    func deleteItem(at offsets: IndexSet) {
        unpurchasedItems.remove(atOffsets: offsets)
    }
    
    func deletePurchasedItem(at offsets: IndexSet) {
        purchasedItems.remove(atOffsets: offsets)
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct ItemEditView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var item: Item
    var onSave: (Item) -> Void
    @State private var textAlignment: TextAlignment = .center // Standardinställning för LTR-språk

    var body: some View {
        VStack {
            Picker("Justering", selection: $textAlignment) {
                Text("Vänster").tag(TextAlignment.leading)
                Text("Höger").tag(TextAlignment.trailing)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            TextField("Artikelnamn", text: $item.name)
                .multilineTextAlignment(textAlignment)
                .padding()
            
            Button("Spara") {
                onSave(item)
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
        }
        .onAppear {
                    // Logik för att hantera uppdateringar vid behov
            print("Signal")
            
                }
        .padding()
    }
}

struct ShoppingListView_Previews: PreviewProvider {
    static var previews: some View {
        ShoppingListView()
    }
}

