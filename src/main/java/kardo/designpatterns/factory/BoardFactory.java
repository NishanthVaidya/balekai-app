package kardo.designpatterns.factory;

import kardo.designpatterns.model.Board;

public abstract class BoardFactory {
    public abstract Board createBoard(String name, String ownerId);
}
