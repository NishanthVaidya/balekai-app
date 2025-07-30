package trelllo.designpatterns.factory;

import trelllo.model.Board;

public abstract class BoardFactory {
    public abstract Board createBoard(String name, String ownerId);
}
