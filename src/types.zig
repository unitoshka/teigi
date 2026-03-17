const Phonetic = struct {
    text: ?[]u8 = null,
};

const Definition = struct {
    definition: []u8,
    synonyms: [][]u8,
    antonyms: [][]u8,
    example: ?[]u8 = null,
};

pub const Meaning = struct {
    partOfSpeech: []u8,
    definitions: []Definition,
};

pub const Entry = struct {
    word: []u8,
    phonetic: ?[]u8 = null,
    phonetics: []Phonetic,
    meanings: []Meaning,

    pub fn findPhonetic(self: Entry) ?[]u8 {
        if (self.phonetic) |text| {
            return text;
        }

        for (self.phonetics) |phonetic| {
            if (phonetic.text) |text| {
                if (text.len > 0) return text;
            }
        }

        return null;
    }
};
