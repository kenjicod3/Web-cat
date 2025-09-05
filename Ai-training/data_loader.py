from tensorflow.keras.preprocessing.image import ImageDataGenerator

IMAGE_SIZE = (96,96) #resize to 96x96 pixels
BATCH_SIZE = 32 #Run in batch, 32 images each.

datagen = ImageDataGenerator(
    rescale = 1./255, #Normalize the pixel values of images to [0,1]
    validation_split=0.2, #Splting dataset, 80% for training, 20% for testing.
    rotation_range=20,
    zoom_range=0.2,
    brightness_range=[0.6, 1.3],
    horizontal_flip=True,
    width_shift_range=0.1,
    height_shift_range=0.1,
    fill_mode='nearest',
)

#Loading images from folders
train_generator = datagen.flow_from_directory(
    'data',
    target_size=IMAGE_SIZE,
    batch_size=BATCH_SIZE,
    class_mode='categorical', #encode for labelling
    color_mode='rgb',
    shuffle=True,
    subset='training'
)

val_generator = datagen.flow_from_directory(
    'data',
    target_size=IMAGE_SIZE,
    batch_size=BATCH_SIZE,
    class_mode='categorical',
    color_mode='rgb',
    shuffle=True,
    subset='validation'
)

