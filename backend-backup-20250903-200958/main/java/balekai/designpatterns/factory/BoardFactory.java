package balekai.designpatterns.factory;

import balekai.designpatterns.model.Board;

public abstract class BoardFactory {
    public abstract Board createBoard(String name, String ownerId);
}
